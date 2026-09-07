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
      appBar: AppBar(title: const Text('Personel / Employees')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.person_add),
        label: const Text('Personel Ekle / Add'),
        onPressed: () => _showAddEmployeeDialog(context, ref),
      ),
      body: employees.when(
        data: (emps) => emps.isEmpty
          ? Center(child: Text('Henüz personel yok / No employees yet',
              style: Theme.of(context).textTheme.bodyLarge))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: emps.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final e = emps[i];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: e['active'] == 1 ? AppColors.border : AppColors.error.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.accentGlow,
                        child: Text((e['name'] as String)[0].toUpperCase(),
                          style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e['name'], style: Theme.of(context).textTheme.bodyLarge),
                            Text(e['email'], style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                      Switch(
                        value: e['active'] == 1,
                        activeColor: AppColors.success,
                        onChanged: (_) async {
                          await ApiService.instance.toggleEmployee(e['id']);
                          ref.invalidate(employeesProvider);
                        },
                      ),
                    ],
                  ),
                );
              }),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
        error: (e, _) => Center(child: Text('$e')),
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
        backgroundColor: AppColors.surfaceCard,
        title: const Text('Personel Ekle / Add Employee',
          style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Ad Soyad / Full Name')),
            const SizedBox(height: 10),
            TextField(controller: emailCtrl, keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'E-posta / Email')),
            const SizedBox(height: 10),
            TextField(controller: passCtrl, obscureText: true,
              decoration: const InputDecoration(labelText: 'Şifre / Password')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty || emailCtrl.text.isEmpty || passCtrl.text.isEmpty) return;
              await ApiService.instance.createEmployee({
                'name': nameCtrl.text.trim(),
                'email': emailCtrl.text.trim(),
                'password': passCtrl.text.trim(),
              });
              ref.invalidate(employeesProvider);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Ekle / Add')),
        ],
      ),
    );
  }
}
