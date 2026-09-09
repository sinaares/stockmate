import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/services/api_service.dart';
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
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text(
          isTR ? 'Ayarlar' : 'Settings',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF4F8EF7),
          indicatorWeight: 3,
          labelColor: const Color(0xFF4F8EF7),
          unselectedLabelColor: const Color(0xFF8B949E),
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          tabs: [
            Tab(icon: const Icon(Icons.person_outline_rounded, size: 18),
                text: isTR ? 'Profil' : 'Profile'),
            Tab(icon: const Icon(Icons.lock_outline_rounded, size: 18),
                text: isTR ? 'Şifre' : 'Password'),
            Tab(icon: const Icon(Icons.tune_rounded, size: 18),
                text: isTR ? 'Genel' : 'General'),
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
      setState(() { _message = isTR ? 'İsim en az 2 karakter olmalı' : 'Name must be at least 2 characters'; _success = false; });
      return;
    }
    setState(() { _loading = true; _message = null; });
    try {
      await ApiService.instance.updateProfile(_nameCtrl.text.trim());
      await ref.read(authProvider.notifier).updateName(_nameCtrl.text.trim());
      setState(() {
        _message = isTR ? 'Profil güncellendi ✓' : 'Profile updated ✓';
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
          const SizedBox(height: 12),
          // Avatar
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF4F8EF7), Color(0xFF7B5FFF)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              boxShadow: [BoxShadow(color: const Color(0xFF4F8EF7).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: Center(
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(user.email, style: const TextStyle(color: Color(0xFF8B949E), fontSize: 13)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: user.isBoss ? const Color(0xFF4F8EF7).withOpacity(0.15) : const Color(0xFF2EA043).withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: user.isBoss ? const Color(0xFF4F8EF7).withOpacity(0.4) : const Color(0xFF2EA043).withOpacity(0.4)),
            ),
            child: Text(
              user.isBoss ? '👑 Boss' : (isTR ? '👷 Çalışan' : '👷 Employee'),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: user.isBoss ? const Color(0xFF4F8EF7) : const Color(0xFF2EA043)),
            ),
          ),
          const SizedBox(height: 32),
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isTR ? 'Ad Soyad' : 'Full Name',
                    style: const TextStyle(color: Color(0xFF8B949E), fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration(isTR ? 'Adınızı girin' : 'Enter your name', Icons.person_outline_rounded),
                ),
                const SizedBox(height: 16),
                Text(isTR ? 'E-posta' : 'Email',
                    style: const TextStyle(color: Color(0xFF8B949E), fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: user.email,
                  enabled: false,
                  style: const TextStyle(color: Color(0xFF8B949E)),
                  decoration: _inputDecoration(user.email, Icons.email_outlined),
                ),
              ],
            ),
          ),
          if (_message != null) ...[
            const SizedBox(height: 12),
            _buildMessage(_message!, _success),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _save,
              icon: _loading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_rounded, size: 18),
              label: Text(isTR ? 'Kaydet' : 'Save',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F8EF7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: Text(isTR ? 'Çıkış Yap' : 'Sign Out',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFE74C3C),
                side: const BorderSide(color: Color(0xFFE74C3C)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      setState(() { _message = isTR ? 'Yeni şifreler eşleşmiyor' : 'New passwords do not match'; _success = false; });
      return;
    }
    if (_newCtrl.text.length < 6) {
      setState(() { _message = isTR ? 'Şifre en az 6 karakter olmalı' : 'Password must be at least 6 characters'; _success = false; });
      return;
    }
    setState(() { _loading = true; _message = null; });
    try {
      await ApiService.instance.changePassword(_currentCtrl.text, _newCtrl.text);
      _currentCtrl.clear(); _newCtrl.clear(); _confirmCtrl.clear();
      setState(() { _message = isTR ? 'Şifre başarıyla değiştirildi ✓' : 'Password changed successfully ✓'; _success = true; });
    } catch (e) {
      setState(() {
        final err = _parseError(e);
        _message = isTR
            ? (err.contains('incorrect') ? 'Mevcut şifre yanlış' : 'Hata: $err')
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
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF4F8EF7).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF4F8EF7).withOpacity(0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline_rounded, color: Color(0xFF4F8EF7), size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(
                isTR ? 'Güvenliğiniz için güçlü bir şifre kullanın (en az 6 karakter).' : 'Use a strong password for your security (min. 6 characters).',
                style: const TextStyle(color: Color(0xFF4F8EF7), fontSize: 12),
              )),
            ]),
          ),
          const SizedBox(height: 24),
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _pwLabel(isTR ? 'Mevcut Şifre' : 'Current Password'),
                _pwField(_currentCtrl, isTR ? 'Mevcut şifreniz' : 'Your current password', _showCurrent,
                    () => setState(() => _showCurrent = !_showCurrent)),
                const SizedBox(height: 16),
                _pwLabel(isTR ? 'Yeni Şifre' : 'New Password'),
                _pwField(_newCtrl, isTR ? 'En az 6 karakter' : 'At least 6 characters', _showNew,
                    () => setState(() => _showNew = !_showNew)),
                const SizedBox(height: 16),
                _pwLabel(isTR ? 'Yeni Şifre Tekrar' : 'Confirm New Password'),
                _pwField(_confirmCtrl, isTR ? 'Şifreyi tekrar girin' : 'Repeat new password', _showConfirm,
                    () => setState(() => _showConfirm = !_showConfirm)),
              ],
            ),
          ),
          if (_message != null) ...[
            const SizedBox(height: 12),
            _buildMessage(_message!, _success),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _change,
              icon: _loading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.lock_reset_rounded, size: 18),
              label: Text(isTR ? 'Şifreyi Değiştir' : 'Change Password',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F8EF7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pwLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(color: Color(0xFF8B949E), fontSize: 12, fontWeight: FontWeight.w600)),
  );

  Widget _pwField(TextEditingController ctrl, String hint, bool show, VoidCallback toggle) =>
      TextFormField(
        controller: ctrl,
        obscureText: !show,
        style: const TextStyle(color: Colors.white),
        decoration: _inputDecoration(hint, Icons.lock_outline_rounded).copyWith(
          suffixIcon: IconButton(
            icon: Icon(show ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: const Color(0xFF8B949E), size: 18),
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
      setState(() { _message = isTR ? 'Geçerli bir URL girin (http:// ile başlamalı)' : 'Enter a valid URL (must start with http://)'; _success = false; });
      return;
    }
    setState(() { _loading = true; _message = null; });
    try {
      await ApiService.instance.setBaseUrl(url);
      setState(() { _message = isTR ? 'Sunucu URL\'si kaydedildi ✓' : 'Server URL saved ✓'; _success = true; });
    } catch (e) {
      setState(() { _message = 'Error: ${_parseError(e)}'; _success = false; });
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
          const SizedBox(height: 12),

          // Language Selection
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.language_rounded, color: Color(0xFF4F8EF7), size: 20),
                  const SizedBox(width: 10),
                  Text(isTR ? 'Dil / Language' : 'Language / Dil',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                ]),
                const SizedBox(height: 16),
                Row(children: [
                  _langOption(context, '🇹🇷 Türkçe', 'tr', currentLang),
                  const SizedBox(width: 12),
                  _langOption(context, '🇬🇧 English', 'en', currentLang),
                ]),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Server URL
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.dns_outlined, color: Color(0xFF4F8EF7), size: 20),
                  const SizedBox(width: 10),
                  Text(isTR ? 'Sunucu Bağlantısı' : 'Server Connection',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                ]),
                const SizedBox(height: 6),
                Text(
                  isTR ? 'Backend sunucunuzun adresini girin' : 'Enter your backend server address',
                  style: const TextStyle(color: Color(0xFF8B949E), fontSize: 12),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _urlCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  keyboardType: TextInputType.url,
                  decoration: _inputDecoration(
                    'http://192.168.1.100:3000',
                    Icons.link_rounded,
                  ),
                ),
                const SizedBox(height: 12),
                // Quick preset buttons
                Text(isTR ? 'Hızlı seçenekler:' : 'Quick presets:',
                    style: const TextStyle(color: Color(0xFF8B949E), fontSize: 11)),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _presetBtn('localhost:3000', 'http://localhost:3000'),
                  _presetBtn('127.0.0.1:3000', 'http://127.0.0.1:3000'),
                  _presetBtn('10.0.2.2:3000', 'http://10.0.2.2:3000'),
                ]),
                if (_message != null) ...[
                  const SizedBox(height: 12),
                  _buildMessage(_message!, _success),
                ],
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _saveUrl,
                    icon: _loading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save_rounded, size: 18),
                    label: Text(isTR ? 'Kaydet' : 'Save',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F8EF7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // App Info
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.info_outline_rounded, color: Color(0xFF4F8EF7), size: 20),
                  const SizedBox(width: 10),
                  Text(isTR ? 'Uygulama Hakkında' : 'About App',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                ]),
                const SizedBox(height: 14),
                _infoRow(isTR ? 'Uygulama' : 'App', 'StockMate'),
                _infoRow(isTR ? 'Sürüm' : 'Version', '1.0.0'),
                _infoRow(isTR ? 'Platform' : 'Platform', 'Flutter 3.47'),
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
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF4F8EF7).withOpacity(0.15) : const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? const Color(0xFF4F8EF7) : const Color(0xFF30363D),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: Text(label, style: TextStyle(
              color: selected ? const Color(0xFF4F8EF7) : const Color(0xFF8B949E),
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13,
            )),
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
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Text(label, style: const TextStyle(color: Color(0xFF8B949E), fontSize: 11)),
    ),
  );

  Widget _infoRow(String key, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(key, style: const TextStyle(color: Color(0xFF8B949E), fontSize: 13)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    ),
  );
}

// ─── Shared Helpers ──────────────────────────────────────────────────────────
Widget _buildCard({required Widget child}) => Container(
  width: double.infinity,
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: const Color(0xFF161B22),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: const Color(0xFF30363D)),
  ),
  child: child,
);

Widget _buildMessage(String msg, bool success) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
  decoration: BoxDecoration(
    color: (success ? const Color(0xFF2EA043) : const Color(0xFFDA3633)).withOpacity(0.12),
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: (success ? const Color(0xFF2EA043) : const Color(0xFFDA3633)).withOpacity(0.4)),
  ),
  child: Row(children: [
    Icon(success ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
        color: success ? const Color(0xFF2EA043) : const Color(0xFFDA3633), size: 16),
    const SizedBox(width: 8),
    Expanded(child: Text(msg, style: TextStyle(
      color: success ? const Color(0xFF2EA043) : const Color(0xFFDA3633),
      fontSize: 13,
    ))),
  ]),
);

InputDecoration _inputDecoration(String hint, IconData icon) => InputDecoration(
  hintText: hint,
  hintStyle: const TextStyle(color: Color(0xFF8B949E)),
  prefixIcon: Icon(icon, color: const Color(0xFF8B949E), size: 18),
  filled: true,
  fillColor: const Color(0xFF0D1117),
  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: Color(0xFF30363D)),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: Color(0xFF30363D)),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: Color(0xFF4F8EF7), width: 1.5),
  ),
  disabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: Color(0xFF21262D)),
  ),
);

String _parseError(dynamic e) {
  final s = e.toString();
  if (s.contains('"error"')) {
    final start = s.indexOf('"error"') + 9;
    final end = s.indexOf('"', start);
    if (end > start) return s.substring(start, end);
  }
  if (s.contains('401')) return 'Unauthorized';
  if (s.contains('connection')) return 'Cannot reach server';
  return s.length > 60 ? '${s.substring(0, 60)}...' : s;
}
