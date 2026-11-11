import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/services/api_service.dart';
import '../../../core/constants/app_colors.dart';

final employeesProvider = FutureProvider<List<dynamic>>((ref) => ApiService.instance.getEmployees());

class EmployeesScreen extends ConsumerWidget {
  const EmployeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employees = ref.watch(employeesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Personel & Kullanıcı Yönetimi'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Personel Ekle', style: TextStyle(fontWeight: FontWeight.w700)),
        onPressed: () => _showAddEmployeeDialog(context, ref),
      ),
      body: employees.when(
        data: (emps) => emps.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.group_outlined, color: AppColors.textHint, size: 36),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Kayıtlı personel bulunamadı',
                      style: TextStyle(color: AppColors.navy, fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Sisteme yeni çalışan hesabı eklemek için aşağıdaki butonu kullanın.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(employeesProvider),
                color: AppColors.primary,
                backgroundColor: Colors.white,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                  itemCount: emps.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final e = emps[i];
                    final isActive = e['active'] == 1;

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isActive ? AppColors.border : AppColors.errorBorder,
                        ),
                        boxShadow: AppColors.cardShadow,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: isActive ? AppColors.primaryTint : AppColors.surfaceMuted,
                            child: Text(
                              (e['name'] as String).isNotEmpty ? (e['name'] as String)[0].toUpperCase() : 'P',
                              style: TextStyle(
                                color: isActive ? AppColors.primary : AppColors.textHint,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      e['name'] ?? '',
                                      style: const TextStyle(
                                        color: AppColors.navy,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceMuted,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        e['role'] == 'boss' ? 'Yönetici' : 'Çalışan',
                                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  e['email'] ?? '',
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Switch(
                                value: isActive,
                                activeColor: AppColors.teal,
                                onChanged: (_) async {
                                  await ApiService.instance.toggleEmployee(e['id']);
                                  ref.invalidate(employeesProvider);
                                },
                              ),
                              Text(
                                isActive ? 'Aktif' : 'Devre Dışı',
                                style: TextStyle(
                                  color: isActive ? AppColors.teal : AppColors.error,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('$e', style: const TextStyle(color: AppColors.error))),
      ),
    );
  }

  void _showAddEmployeeDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Yeni Personel Hesabı',
          style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w700, fontSize: 17),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Ad Soyad *',
                hintText: 'Örn: Can Demir',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'E-posta Adresi *',
                hintText: 'calisan@stockmate.local',
                prefixIcon: Icon(Icons.alternate_email_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Şifre *',
                hintText: '••••••••',
                prefixIcon: Icon(Icons.lock_outline_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Vazgeç', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty || passCtrl.text.trim().isEmpty) return;
              await ApiService.instance.createEmployee({
                'name': nameCtrl.text.trim(),
                'email': emailCtrl.text.trim(),
                'password': passCtrl.text.trim(),
              });
              ref.invalidate(employeesProvider);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Personeli Kaydet'),
          ),
        ],
      ),
    );
  }
}
