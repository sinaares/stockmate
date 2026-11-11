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
  final _passCtrl  = TextEditingController();
  final _urlCtrl   = TextEditingController();
  bool _showPass         = false;
  bool _showServerConfig = false;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
    _urlCtrl.text = ApiService.instance.baseUrl;
    _emailCtrl.text = 'boss@stockmate.local';
    _passCtrl.text = 'boss123';
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

  void _fillBoss() {
    _emailCtrl.text = 'boss@stockmate.local';
    _passCtrl.text = 'boss123';
    setState(() {});
  }

  void _fillEmployee() {
    _emailCtrl.text = 'ahmet@stockmate.local';
    _passCtrl.text = 'emp123';
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final auth   = ref.watch(authProvider);
    final size   = MediaQuery.sizeOf(context);
    final isWide = size.width > 860;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: isWide ? _buildWideLayout(auth) : _buildNarrowLayout(auth),
    );
  }

  Widget _buildWideLayout(dynamic auth) {
    return Row(
      children: [
        // Left branding showcase in Deep Navy (#142D4E)
        Expanded(
          flex: 5,
          child: Container(
            color: AppColors.navy,
            child: Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: _DotGridPainter())),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 56),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _BrandLogo(),
                        const SizedBox(height: 32),
                        const Text(
                          'StockMate',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 46,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.5,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Kurumsal Envanter, Depo ve\nTeknik Servis Yönetim Platformu',
                          style: TextStyle(
                            color: Color(0xFFCBD5E1),
                            fontSize: 16,
                            height: 1.5,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 40),
                        const _FeatureCard(
                          icon: Icons.inventory_2_rounded,
                          title: 'Uçtan Uca Stok & Depo Takibi',
                          subtitle: 'Kritik stok uyarıları, varyantlar ve dinamik kategoriler',
                        ),
                        const SizedBox(height: 14),
                        const _FeatureCard(
                          icon: Icons.build_circle_rounded,
                          title: 'Teknik Servis & İş Emirleri',
                          subtitle: 'Cihaz tamir takibi, maliyet hesaplama ve teslimat',
                        ),
                        const SizedBox(height: 14),
                        const _FeatureCard(
                          icon: Icons.qr_code_scanner_rounded,
                          title: 'Kamera & Barkod Entegrasyonu',
                          subtitle: 'Hızlı satış, kullanım ve onay mekanizması',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Right Form in Clean White Surface
        Expanded(
          flex: 4,
          child: Container(
            color: AppColors.background,
            child: Center(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                          boxShadow: AppColors.cardShadow,
                        ),
                        child: _buildForm(auth),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(dynamic auth) {
    return SafeArea(
      child: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  children: [
                    const _BrandLogo(),
                    const SizedBox(height: 18),
                    const Text(
                      'StockMate',
                      style: TextStyle(
                        color: AppColors.navy,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Kurumsal Envanter & Teknik Servis Platformu',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                        boxShadow: AppColors.cardShadow,
                      ),
                      child: _buildForm(auth),
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

  Widget _buildForm(dynamic auth) {
    final isBossSelected = _emailCtrl.text.toLowerCase().contains('boss');
    final isEmpSelected  = _emailCtrl.text.toLowerCase().contains('ahmet') || _emailCtrl.text.toLowerCase().contains('mehmet');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Giriş Yap',
          style: TextStyle(
            color: AppColors.navy,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Envanter ve teknik servis sistemine erişin',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 20),
        // Role Quick-Switch Pills
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _fillBoss,
                  borderRadius: BorderRadius.circular(9),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isBossSelected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                      boxShadow: isBossSelected ? AppColors.cardShadow : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shield_rounded,
                          size: 15,
                          color: isBossSelected ? AppColors.primary : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Yönetici (Boss)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isBossSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isBossSelected ? AppColors.navy : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: _fillEmployee,
                  borderRadius: BorderRadius.circular(9),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isEmpSelected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                      boxShadow: isEmpSelected ? AppColors.cardShadow : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.badge_rounded,
                          size: 15,
                          color: isEmpSelected ? AppColors.teal : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Çalışan (Ahmet)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isEmpSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isEmpSelected ? AppColors.navy : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const _FieldLabel('E-posta Adresi veya Kullanıcı Adı'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          textCapitalization: TextCapitalization.none,
          autocorrect: false,
          enableSuggestions: false,
          decoration: const InputDecoration(
            hintText: 'boss@stockmate.local veya ahmet@stockmate.local',
            prefixIcon: Icon(Icons.alternate_email_rounded, size: 18),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        const _FieldLabel('Şifre'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _passCtrl,
          obscureText: !_showPass,
          decoration: InputDecoration(
            hintText: '••••••••',
            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
            suffixIcon: IconButton(
              icon: Icon(
                _showPass ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                size: 18,
                color: AppColors.textHint,
              ),
              onPressed: () => setState(() => _showPass = !_showPass),
            ),
          ),
          onFieldSubmitted: (_) => _login(),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => setState(() => _showServerConfig = !_showServerConfig),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _showServerConfig ? Icons.expand_less_rounded : Icons.tune_rounded,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              const Text(
                'Sunucu Adresi Ayarı',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        if (_showServerConfig) ...[
          const SizedBox(height: 10),
          TextFormField(
            controller: _urlCtrl,
            decoration: const InputDecoration(
              hintText: 'http://localhost:3000',
              prefixIcon: Icon(Icons.dns_outlined, size: 18),
            ),
          ),
        ],
        if (auth.error != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: AppColors.errorTint,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.errorBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    auth.error!,
                    style: const TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: auth.isLoading ? null : _login,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: auth.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                  )
                : const Text(
                    'Giriş Yap',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.2),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.info_outline_rounded, size: 14, color: AppColors.primary),
                  SizedBox(width: 6),
                  Text(
                    'Hazır Test Hesapları',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.navy),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: _fillBoss,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    '• Yönetici: boss@stockmate.local  (Şifre: boss123 veya 123456)',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              InkWell(
                onTap: _fillEmployee,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    '• Çalışan: ahmet@stockmate.local  (Şifre: emp123 veya 123456)',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            'StockMate Enterprise ERP • v2.0',
            style: TextStyle(color: AppColors.textHint, fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

class _BrandLogo extends StatelessWidget {
  const _BrandLogo();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x332563EB),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 28),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      );
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _FeatureCard({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.teal.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.tealLight, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1;
    const spacing = 28.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.0, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
