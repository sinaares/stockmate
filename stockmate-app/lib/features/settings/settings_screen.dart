import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/services/api_service.dart';
import '../../../core/constants/app_colors.dart';
import '../auth/providers/auth_provider.dart';
import '../../../app.dart'; // themeModeProvider

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
  bool _isBoss = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _isBoss = user?.isBoss ?? false;
    _tabController = TabController(length: _isBoss ? 4 : 3, vsync: this);
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
    final isBoss = user.isBoss;

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
            if (isBoss)
              Tab(icon: const Icon(Icons.cloud_sync_rounded, size: 18), text: 'Netsis ERP'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ProfileTab(lang: lang, user: user),
          _PasswordTab(lang: lang),
          _GeneralTab(lang: lang),
          if (isBoss)
            _NetsisTab(lang: lang),
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

          // ── Dark Mode Toggle Card ──────────────────────────────────────────
          Builder(builder: (context) {
            final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
            final isTR = widget.lang == 'tr';
            return _buildCard(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF21262D) : AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      color: isDark ? const Color(0xFF58A6FF) : AppColors.warning,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isTR ? 'Gece Modu' : 'Dark Mode',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        Text(
                          isDark
                              ? (isTR ? 'Aktif — Koyu tema kullanılıyor' : 'Active — Using dark theme')
                              : (isTR ? 'Pasif — Açık tema kullanılıyor' : 'Inactive — Using light theme'),
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: isDark,
                    onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
            );
          }),
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

// ─── Netsis ERP Tab ──────────────────────────────────────────────────────────
class _NetsisTab extends StatefulWidget {
  final String lang;
  const _NetsisTab({required this.lang});

  @override
  State<_NetsisTab> createState() => _NetsisTabState();
}

class _NetsisTabState extends State<_NetsisTab> {
  bool _loading = true;
  bool _saving = false;
  bool _testing = false;
  bool _syncing = false;
  String? _message;
  bool _messageSuccess = false;
  String? _testResult;
  bool _testSuccess = false;

  String _mode = 'simulation';
  late TextEditingController _hostCtrl;
  late TextEditingController _portCtrl;
  late TextEditingController _dbNameCtrl;
  late TextEditingController _userCtrl;
  late TextEditingController _passwordCtrl;
  late TextEditingController _restUrlCtrl;
  late TextEditingController _warehouseCtrl;
  bool _autoSync = false;
  bool _isActive = true;
  List<dynamic> _logs = [];

  @override
  void initState() {
    super.initState();
    _hostCtrl = TextEditingController(text: '127.0.0.1');
    _portCtrl = TextEditingController(text: '1433');
    _dbNameCtrl = TextEditingController(text: 'NETSIS_2026');
    _userCtrl = TextEditingController(text: 'sa');
    _passwordCtrl = TextEditingController();
    _restUrlCtrl = TextEditingController(text: 'http://localhost:8090/api');
    _warehouseCtrl = TextEditingController(text: '1');
    _loadSettings();
  }

  @override
  void dispose() {
    _hostCtrl.dispose();
    _portCtrl.dispose();
    _dbNameCtrl.dispose();
    _userCtrl.dispose();
    _passwordCtrl.dispose();
    _restUrlCtrl.dispose();
    _warehouseCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _loading = true);
    try {
      final s = await ApiService.instance.getNetsisSettings();
      final logs = await ApiService.instance.getNetsisLogs(10);
      setState(() {
        _mode = s['mode'] ?? 'simulation';
        _hostCtrl.text = s['server_host'] ?? '127.0.0.1';
        _portCtrl.text = (s['server_port'] ?? 1433).toString();
        _dbNameCtrl.text = s['database_name'] ?? 'NETSIS_2026';
        _userCtrl.text = s['db_user'] ?? 'sa';
        _passwordCtrl.text = s['db_password_masked'] ?? '';
        _restUrlCtrl.text = s['rest_url'] ?? 'http://localhost:8090/api';
        _warehouseCtrl.text = (s['warehouse_code'] ?? 1).toString();
        _autoSync = s['auto_sync_stock'] ?? false;
        _isActive = s['is_active'] ?? true;
        _logs = logs;
      });
    } catch (e) {
      setState(() {
        _message = 'Netsis ayarları yüklenemedi: $e';
        _messageSuccess = false;
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      final payload = {
        'mode': _mode,
        'server_host': _hostCtrl.text.trim(),
        'server_port': int.tryParse(_portCtrl.text.trim()) ?? 1433,
        'database_name': _dbNameCtrl.text.trim(),
        'db_user': _userCtrl.text.trim(),
        'rest_url': _restUrlCtrl.text.trim(),
        'warehouse_code': int.tryParse(_warehouseCtrl.text.trim()) ?? 1,
        'auto_sync_stock': _autoSync,
        'is_active': _isActive,
      };
      if (_passwordCtrl.text.isNotEmpty && !_passwordCtrl.text.contains('*')) {
        payload['db_password'] = _passwordCtrl.text;
      }
      await ApiService.instance.updateNetsisSettings(payload);
      setState(() {
        _message = widget.lang == 'tr' ? 'Netsis ayarları başarıyla kaydedildi ✓' : 'Netsis settings saved successfully ✓';
        _messageSuccess = true;
      });
    } catch (e) {
      setState(() {
        _message = 'Kaydetme hatası: $e';
        _messageSuccess = false;
      });
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _testing = true;
      _testResult = null;
    });
    try {
      final res = await ApiService.instance.testNetsisConnection();
      setState(() {
        _testSuccess = res['success'] == true;
        _testResult = res['message'] ?? 'Bağlantı kontrolü tamamlandı.';
      });
    } catch (e) {
      setState(() {
        _testSuccess = false;
        _testResult = 'Hata: $e';
      });
    } finally {
      setState(() => _testing = false);
    }
  }

  Future<void> _syncProducts() async {
    setState(() {
      _syncing = true;
      _message = null;
    });
    try {
      final res = await ApiService.instance.syncNetsisProducts();
      final total = res['totalSynced'] ?? 0;
      final inserted = res['insertedCount'] ?? 0;
      final updated = res['updatedCount'] ?? 0;
      final logs = await ApiService.instance.getNetsisLogs(10);
      setState(() {
        _message = widget.lang == 'tr'
            ? 'Senkronizasyon Başarılı: $total ürün eşitlendi ($inserted yeni, $updated güncellendi) ✓'
            : 'Sync Complete: $total items synced ($inserted new, $updated updated) ✓';
        _messageSuccess = true;
        _logs = logs;
      });
    } catch (e) {
      setState(() {
        _message = 'Senkronizasyon hatası: $e';
        _messageSuccess = false;
      });
    } finally {
      setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTR = widget.lang == 'tr';

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner / Durum Kartı
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _mode == 'simulation' ? const Color(0xFF1E293B) : const Color(0xFF0F766E),
                  const Color(0xFF0F172A),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.cloud_sync_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isTR ? 'Logo Netsis ERP Entegrasyonu' : 'Logo Netsis ERP Integration',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _mode == 'simulation'
                            ? (isTR ? '● Simülasyon (Test & Demo Modu)' : '● Simulation (Test Mode)')
                            : _mode == 'mssql'
                                ? (isTR ? '● Doğrudan MS SQL Bağlantısı' : '● Direct MS SQL Connection')
                                : (isTR ? '● Netsis REST Servisi' : '● Netsis REST Service'),
                        style: TextStyle(
                          color: _mode == 'simulation' ? const Color(0xFF38BDF8) : const Color(0xFF34D399),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (_message != null) ...[
            _buildMessage(_message!, _messageSuccess),
            const SizedBox(height: 16),
          ],

          if (_testResult != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _testSuccess ? AppColors.tealTint : AppColors.errorTint,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _testSuccess ? AppColors.teal : AppColors.error),
              ),
              child: Row(
                children: [
                  Icon(_testSuccess ? Icons.check_circle : Icons.error, color: _testSuccess ? AppColors.teal : AppColors.error, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _testResult!,
                      style: TextStyle(color: _testSuccess ? AppColors.teal : AppColors.error, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Hızlı Eylemler (Test & Eşitleme)
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isTR ? 'Hızlı ERP İşlemleri' : 'Quick ERP Actions',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.navy),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _testing ? null : _testConnection,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: _testing
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.wifi_tethering_rounded, size: 18),
                        label: Text(isTR ? 'Bağlantıyı Test Et' : 'Test Connection', style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _syncing ? null : _syncProducts,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D9488),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: _syncing
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.sync_rounded, size: 18),
                        label: Text(isTR ? 'Şimdi Senkronize Et' : 'Sync Products', style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Yapılandırma Kartı
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isTR ? 'Bağlantı & Entegrasyon Ayarları' : 'Connection & Integration Settings',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.navy),
                ),
                const SizedBox(height: 16),

                // Mod Seçimi
                Text(isTR ? 'Entegrasyon Modu' : 'Integration Mode', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _mode,
                      isExpanded: true,
                      items: [
                        DropdownMenuItem(
                          value: 'simulation',
                          child: Text(isTR ? '🧪 Simülasyon (Test/Demo - Canlı DB Gerekmez)' : '🧪 Simulation (Mock/Demo)'),
                        ),
                        DropdownMenuItem(
                          value: 'mssql',
                          child: Text(isTR ? '🗄️ Doğrudan MS SQL (TBLSTSABIT & TBLSTOKURS)' : '🗄️ Direct MS SQL (Native)'),
                        ),
                        DropdownMenuItem(
                          value: 'rest',
                          child: Text(isTR ? '🌐 Netsis REST API Servisi' : '🌐 Netsis REST API Gateway'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _mode = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                if (_mode == 'mssql') ...[
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _hostCtrl,
                          decoration: _inputDecoration(isTR ? 'Sunucu IP/Host (192.168.1.50)' : 'Server Host', Icons.dns_rounded),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: _portCtrl,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration('Port', Icons.numbers_rounded),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _dbNameCtrl,
                    decoration: _inputDecoration(isTR ? 'Veritabanı Adı (örn: SIRKET_2026)' : 'Database Name', Icons.storage_rounded),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _userCtrl,
                          decoration: _inputDecoration(isTR ? 'SQL Kullanıcı Adı (sa)' : 'SQL Username', Icons.person_rounded),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _passwordCtrl,
                          obscureText: true,
                          decoration: _inputDecoration(isTR ? 'SQL Şifresi' : 'SQL Password', Icons.lock_rounded),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                if (_mode == 'rest') ...[
                  TextField(
                    controller: _restUrlCtrl,
                    decoration: _inputDecoration(isTR ? 'REST API URL (http://...)' : 'REST API URL', Icons.link_rounded),
                  ),
                  const SizedBox(height: 12),
                ],

                TextField(
                  controller: _warehouseCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(isTR ? 'Depo Kodu (Varsayılan: 1)' : 'Warehouse Code', Icons.warehouse_rounded),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _saveSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _saving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(isTR ? 'Ayarları Kaydet' : 'Save Settings', style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Son Entegrasyon Logları
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isTR ? 'Son Senkronizasyon & Fiş Hareketleri' : 'Recent ERP Logs',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.navy),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, size: 18, color: AppColors.primary),
                      onPressed: _loadSettings,
                      tooltip: isTR ? 'Yenile' : 'Refresh',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_logs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        isTR ? 'Henüz kaydedilmiş ERP işlemi yok.' : 'No ERP actions recorded yet.',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _logs.length,
                    separatorBuilder: (_, __) => const Divider(height: 16),
                    itemBuilder: (context, i) {
                      final item = _logs[i];
                      final isSuccess = item['status'] == 'success';
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            isSuccess ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                            color: isSuccess ? AppColors.teal : AppColors.error,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['message'] ?? '',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.navy),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item['created_at'] != null ? item['created_at'].toString().split('T').first : '',
                                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
