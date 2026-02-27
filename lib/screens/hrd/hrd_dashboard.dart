import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../models/models.dart';

class HrdDashboard extends StatefulWidget {
  const HrdDashboard({super.key});
  @override State<HrdDashboard> createState() => _State();
}

class _State extends State<HrdDashboard> {
  Map<String, dynamic>? _stats;
  List<AttendanceModel> _todayAtt   = [];
  List<LeaveModel>   _pendingLeaves = [];
  Map<String, List<AttendanceModel>> _weekAtt = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });
    try {
      final svc     = context.read<SupabaseService>();
      final stats   = await svc.getDashboardStats();
      final today   = await svc.fetchAttendances(date: DateTime.now());
      final pending = await svc.fetchLeaves(status: LeaveStatus.pending);
      final weekMap = <String, List<AttendanceModel>>{};
      for (int i = 4; i >= 0; i--) {
        final d   = DateTime.now().subtract(Duration(days: i));
        final key = d.toIso8601String().substring(0, 10);
        weekMap[key] = await svc.fetchAttendances(date: d);
      }
      if (!mounted) return;
      setState(() { _stats = stats; _todayAtt = today; _pendingLeaves = pending; _weekAtt = weekMap; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = '$e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.wifi_off_rounded, size: 56, color: AppColors.accent),
        const SizedBox(height: 16),
        const Text('Gagal memuat dashboard', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(_error!, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        const SizedBox(height: 24),
        ElevatedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Coba Lagi')),
      ]));
    }

    final stats = _stats!;
    final today = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now());

    return RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Dashboard HRD', style: Theme.of(context).textTheme.headlineLarge),
                  const SizedBox(height: 4),
                  Text(today, style: Theme.of(context).textTheme.bodyMedium),
                ]),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Row(children: [
                    const Icon(Icons.notifications_outlined, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text('${stats['pendingLeaves']} Pengajuan', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ]),
              const SizedBox(height: 28),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  StatCard(title: 'Total Karyawan', value: '${stats['totalEmployees']}', subtitle: 'Karyawan aktif', icon: Icons.people_rounded, gradientColors: [AppColors.primary, AppColors.info]),
                  const SizedBox(width: 16),
                  StatCard(title: 'Hadir Hari Ini', value: '${stats['presentToday']}', subtitle: 'dari ${stats['totalEmployees']} karyawan', icon: Icons.check_circle_rounded, gradientColors: [AppColors.success, const Color(0xFF10B981)]),
                  const SizedBox(width: 16),
                  StatCard(title: 'Tidak Hadir', value: '${stats['absentToday']}', subtitle: 'Hari ini', icon: Icons.cancel_rounded, gradientColors: [AppColors.accent, AppColors.accentOrange]),
                  const SizedBox(width: 16),
                  StatCard(title: 'Pengajuan Cuti', value: '${stats['pendingLeaves']}', subtitle: 'Menunggu persetujuan', icon: Icons.beach_access_rounded, gradientColors: [AppColors.accentOrange, AppColors.warning]),
                  const SizedBox(width: 16),
                  StatCard(title: 'Total Gaji', value: formatCurrency(stats['totalSalaryThisMonth']), subtitle: 'Bulan ini', icon: Icons.account_balance_wallet_rounded, gradientColors: [const Color(0xFF8B5CF6), const Color(0xFFEC4899)]),
                ]),
              ),
              const SizedBox(height: 28),

              LayoutBuilder(builder: (context, c) {
                if (c.maxWidth > 700) {
                  return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(flex: 3, child: _attendanceChart()),
                    const SizedBox(width: 20),
                    Expanded(flex: 2, child: _leaveChart()),
                  ]);
                }
                return Column(children: [_attendanceChart(), const SizedBox(height: 20), _leaveChart()]);
              }),
              const SizedBox(height: 24),

              LayoutBuilder(builder: (context, c) {
                if (c.maxWidth > 700) {
                  return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: _todayAttTable()),
                    const SizedBox(width: 20),
                    Expanded(child: _pendingLeavesCard()),
                  ]);
                }
                return Column(children: [_todayAttTable(), const SizedBox(height: 20), _pendingLeavesCard()]);
              }),
            ],
          ),
        ),
    );
  }

  Widget _attendanceChart() {
    final sortedKeys = _weekAtt.keys.toList()..sort();
    final dayLabels  = sortedKeys.map((k) {
      final d = DateTime.parse(k);
      const names = ['Sen','Sel','Rab','Kam','Jum','Sab','Min'];
      return names[d.weekday - 1];
    }).toList();
    final bars = List.generate(sortedKeys.length, (i) {
      final list = _weekAtt[sortedKeys[i]] ?? [];
      final cnt  = list.where((a) => a.status == AttendanceStatus.present || a.status == AttendanceStatus.late).length.toDouble();
      return BarChartGroupData(x: i, barRods: [BarChartRodData(toY: cnt, color: AppColors.primary, width: 20, borderRadius: BorderRadius.circular(6))]);
    });

    return GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Tren Kehadiran (5 Hari)', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text('Jumlah karyawan hadir per hari', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 20),
        SizedBox(
          height: 180,
          child: BarChart(BarChartData(
            barGroups: bars,
            gridData: FlGridData(show: true, drawVerticalLine: false,
                getDrawingHorizontalLine: (v) => const FlLine(color: Color(0xFFEEEEF5), strokeWidth: 1)),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28,
                  getTitlesWidget: (v, _) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 11, color: AppColors.textMuted)))),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
                  getTitlesWidget: (v, _) {
                    final idx = v.toInt();
                    return Text(idx < dayLabels.length ? dayLabels[idx] : '',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary));
                  })),
            ),
          )),
        ),
      ]),
    );
  }

  Widget _leaveChart() {
    final approved = _pendingLeaves.where((l) => l.status == LeaveStatus.approved).length;
    final pending  = _pendingLeaves.where((l) => l.status == LeaveStatus.pending).length;
    final rejected = _pendingLeaves.where((l) => l.status == LeaveStatus.rejected).length;

    return GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Status Pengajuan Cuti', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 20),
        SizedBox(
          height: 160,
          child: PieChart(PieChartData(
            sections: [
              if (pending  > 0) PieChartSectionData(value: pending.toDouble(),  color: AppColors.warning, title: '$pending',  radius: 60, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
              if (approved > 0) PieChartSectionData(value: approved.toDouble(), color: AppColors.success, title: '$approved', radius: 60, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
              if (rejected > 0) PieChartSectionData(value: rejected.toDouble(), color: AppColors.accent,  title: '$rejected', radius: 60, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
              if (pending + approved + rejected == 0)
                PieChartSectionData(value: 1, color: const Color(0xFFEEEEF5), title: '', radius: 60),
            ],
            centerSpaceRadius: 40, sectionsSpace: 3,
          )),
        ),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _leg('Menunggu', AppColors.warning),
          _leg('Disetujui', AppColors.success),
          _leg('Ditolak',  AppColors.accent),
        ]),
      ]),
    );
  }

  Widget _leg(String l, Color c) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
    const SizedBox(width: 6),
    Text(l, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
  ]);

  Widget _todayAttTable() {
    return GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionHeader(title: 'Kehadiran Hari Ini', subtitle: '${_todayAtt.length} karyawan tercatat'),
        const SizedBox(height: 16),
        if (_todayAtt.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(20),
              child: Text('Belum ada absensi hari ini', style: TextStyle(color: AppColors.textMuted))))
        else
          ..._todayAtt.take(5).map((a) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(children: [
              AvatarWidget(initials: a.employeeName.split(' ').map((w) => w.isEmpty ? '' : w[0]).take(2).join(), size: 36),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(a.employeeName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text('${a.checkIn ?? '-'} - ${a.checkOut ?? 'Belum checkout'}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ])),
              StatusBadge(label: a.status.label, color: a.status.color),
            ]),
          )),
      ]),
    );
  }

  Widget _pendingLeavesCard() {
    final svc = context.read<SupabaseService>();
    return GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionHeader(title: 'Pengajuan Menunggu', subtitle: '${_pendingLeaves.length} perlu tindakan'),
        const SizedBox(height: 16),
        if (_pendingLeaves.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(20),
              child: Text('Tidak ada pengajuan', style: TextStyle(color: AppColors.textMuted))))
        else
          ..._pendingLeaves.take(5).map((leave) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              AvatarWidget(initials: leave.employeeName.split(' ').map((w) => w.isEmpty ? '' : w[0]).take(2).join(), size: 34),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(leave.employeeName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text('${leave.type.label} • ${leave.duration} hari',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ])),
              Row(mainAxisSize: MainAxisSize.min, children: [
                _actionBtn(Icons.check, AppColors.success, () async {
                  await svc.updateLeaveStatus(leave.id, LeaveStatus.approved);
                  await _load();
                }),
                const SizedBox(width: 6),
                _actionBtn(Icons.close, AppColors.accent, () async {
                  await svc.updateLeaveStatus(leave.id, LeaveStatus.rejected);
                  await _load();
                }),
              ]),
            ]),
          )),
      ]),
    );
  }

  Widget _actionBtn(IconData icon, Color color, VoidCallback onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, color: color, size: 16),
    ),
  );
}
