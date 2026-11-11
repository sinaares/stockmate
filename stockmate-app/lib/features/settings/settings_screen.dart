import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/services/api_service.dart';
import '../../../core/constants/app_colors.dart';
import '../auth/providers/auth_provider.dart';

// ─── Language Provider ────────────────────────────────────────────────────────
final languageProvider = StateProvider<String>((ref) => 'tr'); // 'tr' or 'en'

// ─── Settings Screen ──────────────────────────────────────────────────────────
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final user = ref.watch(authProvider).user!;
    final isTR = lang == 'tr';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          isTR ? 'Sistem Ayarları' : 'Settings',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 2.5,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: [
            Tab(icon: const Icon(Icons.person_outline_rounded, size: 18), text: isTR ? 'Profil' : 'Profile'),
            Tab(icon: const Icon(Icons.lock_outline_rounded, size: 18), text: isTR ? 'Şifre' : 'Password'),
            Tab(icon: const Icon(Icons.tune_rounded, size: 18), text: isTR ? 'Genel' : 'General'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ProfileTab(lang: lang, user: user),
          _PasswordTab(lang: lang),
          _GeneralTab(lang: lang),
        ],
      ),
    );
  }
}

// ─── Profile Tab ─────────────────────────────────────────────────────────────
class _ProfileTab extends ConsumerStatefulWidget {
  final String lang;
  final dynamic user;
  const _ProfileTab({required this.lang, required this.user});

  @override
  ConsumerState<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<_ProfileTab> {
  late TextEditingController _nameCtrl;
  bool _loading = false;
  String? _message;
  bool _success = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.name);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final isTR = widget.lang == 'tr';
    if (_nameCtrl.text.trim().length < 2) {
      setState(() {
        _message = isTR ? 'İsim en az 2 karakter olmalıdır' : 'Name must be at least 2 characters';
        _success = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      await ApiService.instance.updateProfile(_nameCtrl.text.trim());
      await ref.read(authProvider.notifier).updateName(_nameCtrl.text.trim());
      setState(() {
        _message = isTR ? 'Profil başarıyla güncellendi ✓' : 'Profile updated successfully ✓';
        _success = true;
      });
    } catch (e) {
      setState(() {
        _message = isTR ? 'Hata: ${_parseError(e)}' : 'Error: ${_parseError(e)}';
        _success = false;
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTR = widget.lang == 'tr';
    final user = widget.user;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Avatar Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
              boxShadow: AppColors.cardShadow,
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.navy,
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user.name,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(user.email, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: user.isBoss ? AppColors.primaryTint : AppColors.tealTint,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: user.isBoss ? AppColors.primary.withOpacity(0.3) : AppColors.teal.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    user.isBoss ? '👑 Yönetici / Boss' : (isTR ? '👷 Çalışan' : '👷 Employee'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: user.isBoss ? AppColors.primary : AppColors.teal,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Edit Form Card
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isTR ? 'Ad Soyad' : 'Full Name',
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: _inputDecoration(isTR ? 'Adınızı girin' : 'Enter your name', Icons.person_outline_rounded),
                ),
                const SizedBox(height: 14),
                Text(
                  isTR ? 'E-posta Adresi' : 'Email Address',
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  initialValue: user.email,
                  enabled: false,
                  decoration: _inputDecoration(user.email, Icons.email_outlined),
                ),
              ],
            ),
          ),
          if (_message != null) ...[
            const SizedBox(height: 12),
            _buildMessage(_message!, _success),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _save,
              icon: _loading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_rounded, size: 18),
              label: Text(isTR ? 'Değişiklikleri Kaydet' : 'Save Changes', style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.logout_rounded, size: 18, color: AppColors.error),
              label: Text(
                isTR ? 'Oturumu Kapat' : 'Sign Out',
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.error),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.errorBorder),
                backgroundColor: AppColors.errorTint,
              ),
              onPressed: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Password Tab ─────────────────────────────────────────────────────────────
class _PasswordTab extends ConsumerStatefulWidget {
  final String lang;
  const _PasswordTab({required this.lang});

  @override
  ConsumerState<_PasswordTab> createState() => _PasswordTabState();
}

class _PasswordTabState extends ConsumerState<_PasswordTab> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  String? _message;
  bool _success = false;
  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _change() async {
    final isTR = widget.lang == 'tr';
    if (_newCtrl.text != _confirmCtrl.text) {
      setState(() {
        _message = isTR ? 'Yeni şifreler eşleşmiyor' : 'New passwords do not match';
        _success = false;
      });
      return;
    }
    if (_newCtrl.text.length < 6) {
      setState(() {
        _message = isTR ? 'Şifre en az 6 karakter olmalıdır' : 'Password must be at least 6 characters';
        _success = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      await ApiService.instance.changePassword(_currentCtrl.text, _newCtrl.text);
      _currentCtrl.clear();
      _newCtrl.clear();
      _confirmCtrl.clear();
      setState(() {
        _message = isTR ? 'Şifre başarıyla güncellendi ✓' : 'Password changed successfully ✓';
        _success = true;
      });
    } catch (e) {
      setState(() {
        final err = _parseError(e);
        _message = isTR
            ? (err.contains('incorrect') ? 'Mevcut şifreniz hatalı' : 'Hata: $err')
            : 'Error: $err';
        _success = false;
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTR = widget.lang == 'tr';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryTint,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isTR
                        ? 'Hesap güvenliğiniz için şifrenizin en az 6 karakter olmasına dikkat edin.'
                        : 'Use at least 6 characters for a secure password.',
                    style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _pwLabel(isTR ? 'Mevcut Şifre' : 'Current Password'),
                _pwField(
                  _currentCtrl,
                  isTR ? 'Mevcut şifreniz' : 'Your current password',
                  _showCurrent,
                  () => setState(() => _showCurrent = !_showCurrent),
                ),
                const SizedBox(height: 14),
                _pwLabel(isTR ? 'Yeni Şifre' : 'New Password'),
                _pwField(
                  _newCtrl,
                  isTR ? 'En az 6 karakter' : 'At least 6 characters',
                  _showNew,
                  () => setState(() => _showNew = !_showNew),
                ),
                const SizedBox(height: 14),
                _pwLabel(isTR ? 'Yeni Şifre Tekrar' : 'Confirm New Password'),
                _pwField(
                  _confirmCtrl,
                  isTR ? 'Yeni şifrenizi tekrar girin' : 'Repeat new password',
                  _showConfirm,
                  () => setState(() => _showConfirm = !_showConfirm),
                ),
              ],
            ),
          ),
          if (_message != null) ...[
            const SizedBox(height: 12),
            _buildMessage(_message!, _success),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _change,
              icon: _loading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.lock_reset_rounded, size: 18),
              label: Text(isTR ? 'Şifreyi Güncelle' : 'Update Password', style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pwLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
      );

  Widget _pwField(TextEditingController ctrl, String hint, bool show, VoidCallback toggle) => TextFormField(
        controller: ctrl,
        obscureText: !show,
        decoration: _inputDecoration(hint, Icons.lock_outline_rounded).copyWith(
          suffixIcon: IconButton(
            icon: Icon(
              show ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: AppColors.textHint,
              size: 18,
            ),
            onPressed: toggle,
          ),
        ),
      );
}

// ─── General Tab ─────────────────────────────────────────────────────────────
class _GeneralTab extends ConsumerStatefulWidget {
  final String lang;
  const _GeneralTab({required this.lang});

  @override
  ConsumerState<_GeneralTab> createState() => _GeneralTabState();
}

class _GeneralTabState extends ConsumerState<_GeneralTab> {
  late TextEditingController _urlCtrl;
  bool _loading = false;
  String? _message;
  bool _success = false;

  @override
  void initState() {
    super.initState();
    _urlCtrl = TextEditingController(text: ApiService.instance.baseUrl);
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveUrl() async {
    final isTR = widget.lang == 'tr';
    final url = _urlCtrl.text.trim();
    if (url.isEmpty || (!url.startsWith('http://') && !url.startsWith('https://'))) {
      setState(() {
        _message = isTR ? 'Geçerli bir URL girin (http:// ile başlamalı)' : 'Enter a valid URL (must start with http://)';
        _success = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      await ApiService.instance.setBaseUrl(url);
      setState(() {
        _message = isTR ? 'Sunucu adresi başarıyla kaydedildi ✓' : 'Server URL saved successfully ✓';
        _success = true;
      });
    } catch (e) {
      setState(() {
        _message = 'Hata: ${_parseError(e)}';
        _success = false;
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTR = widget.lang == 'tr';
    final currentLang = ref.watch(languageProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Language Selection Card
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.language_rounded, color: AppColors.primary, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Uygulama Dili / Language',
                      style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _langOption(context, '🇹🇷 Türkçe', 'tr', currentLang),
                    const SizedBox(width: 12),
                    _langOption(context, '🇬🇧 English', 'en', currentLang),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Server Connection Card
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.dns_outlined, color: AppColors.primary, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Sunucu & Veritabanı Bağlantısı',
                      style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Uygulamanın bağlandığı StockMate API adresi',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _urlCtrl,
                  keyboardType: TextInputType.url,
                  decoration: _inputDecoration('http://localhost:3000', Icons.link_rounded),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Hızlı Seçenekler:',
                  style: TextStyle(color: AppColors.textHint, fontSize: 11, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _presetBtn('localhost:3000', 'http://localhost:3000'),
                    _presetBtn('127.0.0.1:3000', 'http://127.0.0.1:3000'),
                    _presetBtn('10.0.2.2:3000 (Android)', 'http://10.0.2.2:3000'),
                  ],
                ),
                if (_message != null) ...[
                  const SizedBox(height: 12),
                  _buildMessage(_message!, _success),
                ],
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _saveUrl,
                    icon: _loading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save_rounded, size: 18),
                    label: Text(isTR ? 'Sunucu Adresini Kaydet' : 'Save Server URL', style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // About App Card
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.info_outline_rounded, color: AppColors.navy, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Uygulama Bilgileri',
                      style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _infoRow('Yazılım', 'StockMate Enterprise ERP'),
                _infoRow('Sürüm', 'v2.5 Professional'),
                _infoRow('Mimari', 'Flutter Mobile & Web • Node.js • PostgreSQL'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _langOption(BuildContext context, String label, String value, String current) {
    final selected = value == current;
    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(languageProvider.notifier).state = value,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryTint : AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.5 : 1.0,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _presetBtn(String label, String url) => GestureDetector(
        onTap: () => setState(() => _urlCtrl.text = url),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ),
      );

  Widget _infoRow(String key, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(key, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            Text(value, style: const TextStyle(color: AppColors.navy, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

// ─── Shared Helpers ──────────────────────────────────────────────────────────
Widget _buildCard({required Widget child}) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: child,
    );

Widget _buildMessage(String msg, bool success) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: success ? AppColors.tealTint : AppColors.errorTint,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: success ? AppColors.teal.withOpacity(0.3) : AppColors.errorBorder),
      ),
      child: Row(
        children: [
          Icon(
            success ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
            color: success ? AppColors.teal : AppColors.error,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              msg,
              style: TextStyle(
                color: success ? AppColors.teal : AppColors.error,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

InputDecoration _inputDecoration(String hint, IconData icon) => InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 18),
    );

String _parseError(dynamic e) {
  final s = e.toString();
  if (s.contains('"error"')) {
    final start = s.indexOf('"error"') + 9;
    final end = s.indexOf('"', start);
    if (end > start) return s.substring(start, end);
  }
  if (s.contains('401')) return 'Yetkisiz işlem / Oturum geçersiz';
  if (s.contains('connection')) return 'Sunucuya ulaşılamıyor';
  return s.length > 60 ? '${s.substring(0, 60)}...' : s;
}
