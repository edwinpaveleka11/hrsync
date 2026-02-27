import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../models/models.dart';

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key});
  @override State<EmployeeListScreen> createState() => _S();
}
class _S extends State<EmployeeListScreen> {
  List<UserModel> _all = [];
  String _search = '';
  String _filterDept = 'Semua';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final list = await context.read<SupabaseService>().fetchEmployees();
    if (!mounted) return;
    setState(() { _all = list; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final depts = ['Semua', ..._all.map((e) => e.department).where((d) => d.isNotEmpty).toSet().toList()..sort()];
    var filtered = _all;
    if (_filterDept != 'Semua') filtered = filtered.where((e) => e.department == _filterDept).toList();
    if (_search.isNotEmpty) filtered = filtered.where((e) =>
      e.name.toLowerCase().contains(_search.toLowerCase()) ||
      e.email.toLowerCase().contains(_search.toLowerCase())).toList();

    return RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Data Karyawan',
                subtitle: '${_all.length} karyawan terdaftar',
                action: ElevatedButton.icon(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => _AddDialog(onAdded: () { setState(() => _loading = true); _load(); }),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Tambah Karyawan'),
                ),
              ),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  decoration: const InputDecoration(
                    hintText: 'Cari nama atau email...',
                    prefixIcon: Icon(Icons.search_rounded, size: 20),
                  ),
                )),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _filterDept,
                      items: depts.map((d) => DropdownMenuItem<String>(value: d, child: Text(d, style: const TextStyle(fontSize: 14)))).toList(),
                      onChanged: (v) => setState(() => _filterDept = v!),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 20),
              if (filtered.isEmpty)
                const Center(child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Text('Tidak ada karyawan ditemukan', style: TextStyle(color: AppColors.textMuted)),
                ))
              else
                LayoutBuilder(builder: (ctx, c) {
                  final cols = c.maxWidth > 900 ? 3 : c.maxWidth > 600 ? 2 : 1;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.6),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) => _EmpCard(employee: filtered[i], onRefresh: _load),
                  );
                }),
            ],
          ),
        ),
    );
  }
}

class _EmpCard extends StatelessWidget {
  final UserModel employee;
  final VoidCallback onRefresh;
  const _EmpCard({required this.employee, required this.onRefresh});

  void _editSalary(BuildContext context) {
    final ctrl = TextEditingController(text: employee.baseSalary.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (dCtx) {
        bool saving = false;
        return StatefulBuilder(
          builder: (dCtx, setS) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Edit Gaji Pokok'),
              Text(employee.name,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.normal, color: AppColors.textSecondary)),
            ]),
            content: TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Gaji Pokok (Rp)',
                prefixIcon: const Icon(Icons.attach_money_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Batal')),
              ElevatedButton(
                onPressed: saving ? null : () async {
                  final val = double.tryParse(ctrl.text.replaceAll(RegExp(r'[^0-9]'), ''));
                  if (val == null || val <= 0) return;
                  setS(() => saving = true);
                  try {
                    await context.read<SupabaseService>().updateEmployeeBaseSalary(employee.id, val);
                    if (dCtx.mounted) Navigator.pop(dCtx);
                    onRefresh();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Gaji pokok ${employee.name} berhasil diperbarui'),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.all(16),
                      ));
                    }
                  } catch (e) {
                    setS(() => saving = false);
                  }
                },
                child: saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Simpan'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => GlassCard(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        AvatarWidget(initials: employee.avatarInitials, size: 44),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(employee.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              overflow: TextOverflow.ellipsis),
          Text(employee.position.isNotEmpty ? employee.position : 'Karyawan',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          StatusBadge(label: employee.department.isNotEmpty ? employee.department : 'Umum', color: AppColors.primary),
        ])),
      ]),
      const Spacer(),
      const Divider(color: Color(0xFFEEEEF5)),
      // Gaji pokok row dengan tombol edit
      Row(children: [
        const Icon(Icons.payments_rounded, size: 14, color: AppColors.primary),
        const SizedBox(width: 6),
        Expanded(child: Text(
          formatCurrency(employee.baseSalary),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          overflow: TextOverflow.ellipsis,
        )),
        GestureDetector(
          onTap: () => _editSalary(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.edit_rounded, size: 11, color: AppColors.primary),
              SizedBox(width: 3),
              Text('Edit', style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      ]),
      const SizedBox(height: 4),
      Row(children: [
        const Icon(Icons.email_outlined, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Expanded(child: Text(employee.email,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted), overflow: TextOverflow.ellipsis)),
      ]),
    ]),
  );
}

class _AddDialog extends StatefulWidget {
  final VoidCallback onAdded;
  const _AddDialog({required this.onAdded});
  @override State<_AddDialog> createState() => _AddDialogState();
}
class _AddDialogState extends State<_AddDialog> {
  final _name   = TextEditingController();
  final _email  = TextEditingController();
  final _pass   = TextEditingController();
  final _pos    = TextEditingController();
  final _phone  = TextEditingController();
  final _salary = TextEditingController();
  String _dept = 'Engineering';
  bool _saving = false;

  static const _depts = ['Engineering','Marketing','Finance','Design','Operations','Human Resource'];

  @override
  Widget build(BuildContext context) => Dialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    child: Container(
      width: 480,
      padding: const EdgeInsets.all(28),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Tambah Karyawan Baru', style: Theme.of(context).textTheme.headlineSmall),
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
        ]),
        const SizedBox(height: 20),
        _field('Nama Lengkap', _name, 'cth. Budi Santoso'),
        const SizedBox(height: 12),
        _field('Email', _email, 'cth. budi@company.com'),
        const SizedBox(height: 12),
        _field('Password', _pass, 'min. 8 karakter', obscure: true),
        const SizedBox(height: 12),
        _field('Jabatan', _pos, 'cth. Software Engineer'),
        const SizedBox(height: 12),
        _field('No. Telepon', _phone, 'cth. 081234567890'),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _dept,
          decoration: InputDecoration(labelText: 'Departemen', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
          items: _depts.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
          onChanged: (v) => setState(() => _dept = v!),
        ),
        const SizedBox(height: 12),
        _field('Gaji Pokok', _salary, 'cth. 8000000', keyboard: TextInputType.number),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saving ? null : _submit,
            child: _saving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Simpan Karyawan'),
          ),
        ),
      ]),
    ),
  );

  Future<void> _submit() async {
    if (_name.text.isEmpty || _email.text.isEmpty || _pass.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Nama, email, dan password wajib diisi'), backgroundColor: AppColors.accent));
      return;
    }
    setState(() => _saving = true);
    try {
      await context.read<SupabaseService>().addEmployee(
        name: _name.text, email: _email.text, password: _pass.text,
        department: _dept, position: _pos.text, phone: _phone.text,
        baseSalary: double.tryParse(_salary.text) ?? 0,
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onAdded();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Karyawan ${_name.text} berhasil ditambahkan!'), backgroundColor: AppColors.success));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal: $e'), backgroundColor: AppColors.accent));
      }
    }
  }

  Widget _field(String label, TextEditingController ctrl, String hint, {TextInputType? keyboard, bool obscure = false}) =>
    TextField(controller: ctrl, keyboardType: keyboard, obscureText: obscure,
      decoration: InputDecoration(labelText: label, hintText: hint));
}
