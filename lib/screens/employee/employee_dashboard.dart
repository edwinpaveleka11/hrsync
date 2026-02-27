import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../models/models.dart';

class EmployeeDashboard extends StatefulWidget {
  const EmployeeDashboard({super.key});
  @override State<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
  Map<String, int> _summary  = {};
  List<AttendanceModel> _att = [];
  List<LeaveModel>   _leaves = [];
  List<SalaryModel> _salaries = [];
  bool _checkedIn = false;
  bool _loading   = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final svc  = context.read<SupabaseService>();
    final uid  = svc.currentUser!.id;
    final sum  = await svc.getAttendanceSummary(uid);
    final att  = await svc.fetchAttendances(employeeId: uid);
    final lv   = await svc.fetchLeaves(employeeId: uid);
    final sal  = await svc.fetchSalaries(employeeId: uid);
    final ci   = await svc.hasCheckedInToday(uid);
    if (!mounted) return;
    setState(() { _summary = sum; _att = att; _leaves = lv; _salaries = sal; _checkedIn = ci; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final svc  = context.read<SupabaseService>();
    final user = svc.currentUser!;
    final now  = DateTime.now();
    final greeting = now.hour < 12 ? 'Selamat Pagi' : now.hour < 17 ? 'Selamat Siang' : 'Selamat Malam';

    return RefreshIndicator(
        onRefresh: () async { setState(() => _loading = true); await _load(); },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(28),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Welcome hero
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))]),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('$greeting, ${user.name.split(' ').first}! 👋',
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('${user.position} • ${user.department}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 12),
                  Text(DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(now), style: const TextStyle(color: Colors.white60, fontSize: 12)),
                ])),
                Column(children: [
                  GestureDetector(
                    onTap: _checkedIn ? null : () async {
                      await svc.checkIn(user.id);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Check-in berhasil! 💪'), backgroundColor: AppColors.success));
                      setState(() => _loading = true);
                      await _load();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 76, height: 76,
                      decoration: BoxDecoration(shape: BoxShape.circle,
                        color: _checkedIn ? Colors.white.withOpacity(0.15) : Colors.white,
                        border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                        boxShadow: _checkedIn ? [] : [BoxShadow(color: Colors.white.withOpacity(0.3), blurRadius: 16)]),
                      child: Center(child: Icon(_checkedIn ? Icons.check_rounded : Icons.fingerprint_rounded,
                        color: _checkedIn ? Colors.white70 : AppColors.primary, size: 32)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(_checkedIn ? '✓ Sudah Check-in' : 'Tap Check-in', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                ]),
              ]),
            ),
            const SizedBox(height: 22),

            // Stat cards
            SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
              StatCard(title: 'Hari Hadir', value: '${_summary['present'] ?? 0}', subtitle: 'Total hari hadir', icon: Icons.check_circle_rounded, gradientColors: [AppColors.success, const Color(0xFF10B981)], width: 200),
              const SizedBox(width: 14),
              StatCard(title: 'Terlambat',  value: '${_summary['late']    ?? 0}', subtitle: 'Total keterlambatan', icon: Icons.watch_later_rounded, gradientColors: [AppColors.warning, AppColors.accentOrange], width: 200),
              const SizedBox(width: 14),
              StatCard(title: 'Cuti Diambil', value: '${_leaves.where((l) => l.status == LeaveStatus.approved).length}', subtitle: 'Total cuti disetujui', icon: Icons.beach_access_rounded, gradientColors: [AppColors.primary, AppColors.primaryLight], width: 200),
              const SizedBox(width: 14),
              StatCard(title: 'Gaji Terakhir', value: formatCurrency(_salaries.isNotEmpty ? _salaries.first.netSalary : 0), subtitle: 'Bulan ${_salaries.isNotEmpty ? monthName(_salaries.first.month) : '-'}', icon: Icons.account_balance_wallet_rounded, gradientColors: [const Color(0xFF8B5CF6), const Color(0xFFEC4899)], width: 220),
            ])),
            const SizedBox(height: 22),

            LayoutBuilder(builder: (context, c) {
              final wide = c.maxWidth > 700;
              return wide
                ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: _recentAtt()),
                    const SizedBox(width: 20),
                    Expanded(child: _leaveStatus()),
                  ])
                : Column(children: [_recentAtt(), const SizedBox(height: 20), _leaveStatus()]);
            }),
          ]),
        ),
    );
  }

  Widget _recentAtt() => GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('Absensi Terakhir', style: Theme.of(context).textTheme.headlineSmall),
    const SizedBox(height: 4),
    Text('7 hari terakhir', style: Theme.of(context).textTheme.bodyMedium),
    const SizedBox(height: 14),
    if (_att.isEmpty)
      const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Belum ada data', style: TextStyle(color: AppColors.textMuted))))
    else
      ..._att.take(7).map((a) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [
        Container(width: 40, height: 40,
          decoration: BoxDecoration(color: a.status.color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(Icons.fingerprint_rounded, color: a.status.color, size: 18)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(DateFormat('EEE, d MMM', 'id_ID').format(a.date), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Text('${a.checkIn ?? '-'} → ${a.checkOut ?? 'Belum'}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ])),
        StatusBadge(label: a.status.label, color: a.status.color),
      ]))),
  ]));

  Widget _leaveStatus() => GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('Status Cuti Saya', style: Theme.of(context).textTheme.headlineSmall),
    const SizedBox(height: 4),
    Text('Riwayat pengajuan cuti', style: Theme.of(context).textTheme.bodyMedium),
    const SizedBox(height: 14),
    if (_leaves.isEmpty)
      const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Belum ada pengajuan', style: TextStyle(color: AppColors.textMuted))))
    else
      ..._leaves.take(5).map((l) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10),
          border: Border(left: BorderSide(color: l.type.color, width: 3))),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.type.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            Text('${DateFormat('d MMM').format(l.startDate)} – ${DateFormat('d MMM yyyy').format(l.endDate)} • ${l.duration} hari',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ])),
          StatusBadge(label: l.status.label, color: l.status.color),
        ]),
      )),
  ]));
}
