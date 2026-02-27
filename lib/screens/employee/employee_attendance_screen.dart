import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../models/models.dart';

// ══════════════════════════════════════════════════════
// ATTENDANCE
// ══════════════════════════════════════════════════════
class EmployeeAttendanceScreen extends StatefulWidget {
  const EmployeeAttendanceScreen({super.key});
  @override State<EmployeeAttendanceScreen> createState() => _AttState();
}
class _AttState extends State<EmployeeAttendanceScreen> {
  List<AttendanceModel> _att = [];
  Map<String, int> _sum = {};
  bool _checkedIn = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final svc = context.read<SupabaseService>();
      final uid = svc.currentUser!.id;
      _att = await svc.fetchAttendances(employeeId: uid);
      _sum = await svc.getAttendanceSummary(uid);
      _checkedIn = await svc.hasCheckedInToday(uid);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final svc  = context.read<SupabaseService>();
    final user = svc.currentUser!;
    final now  = DateTime.now();
    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SectionHeader(title: 'Absensi Saya', subtitle: 'Rekam kehadiran harian Anda'),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: _checkedIn ? AppColors.successGradient : AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(
                color: (_checkedIn ? AppColors.success : AppColors.primary).withOpacity(0.35),
                blurRadius: 20, offset: const Offset(0, 8),
              )],
            ),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_checkedIn ? 'Sudah check-in hari ini ✓' : 'Belum check-in hari ini',
                  style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(now),
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
                Text(DateFormat('HH:mm').format(now),
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
              ])),
              if (!_checkedIn)
                ElevatedButton.icon(
                  onPressed: () async {
                    await svc.checkIn(user.id);
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Check-in berhasil! 💪'), backgroundColor: AppColors.success));
                    await _load();
                  },
                  icon: const Icon(Icons.fingerprint_rounded, size: 20),
                  label: const Text('Check In'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white, foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12)),
                ),
            ]),
          ),
          const SizedBox(height: 18),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _tile('Hadir',     '${_sum['present'] ?? 0}', AppColors.success),
              const SizedBox(width: 10),
              _tile('Terlambat', '${_sum['late']    ?? 0}', AppColors.warning),
              const SizedBox(width: 10),
              _tile('Absen',     '${_sum['absent']  ?? 0}', AppColors.accent),
              const SizedBox(width: 10),
              _tile('Cuti',      '${_sum['leave']   ?? 0}', AppColors.primary),
            ]),
          ),
          const SizedBox(height: 22),
          GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Riwayat Absensi', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 14),
            if (_att.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(20),
                child: Text('Belum ada data absensi', style: TextStyle(color: AppColors.textMuted))))
            else
              ..._att.map((a) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: a.status.color.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: a.status.color.withOpacity(0.2))),
                child: Row(children: [
                  Icon(Icons.fingerprint_rounded, color: a.status.color, size: 22),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(a.date),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    Text('Check-in: ${a.checkIn ?? "-"}  •  Check-out: ${a.checkOut ?? "Belum"}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ])),
                  StatusBadge(label: a.status.label, color: a.status.color),
                ]),
              )),
          ])),
        ]),
      ),
    );
  }

  Widget _tile(String l, String v, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
    decoration: BoxDecoration(
      color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(12),
      border: Border.all(color: c.withOpacity(0.3))),
    child: Column(children: [
      Text(v, style: TextStyle(color: c, fontSize: 22, fontWeight: FontWeight.w700)),
      Text(l, style: TextStyle(color: c.withOpacity(0.8), fontSize: 12)),
    ]),
  );
}

// ══════════════════════════════════════════════════════
// LEAVE
// ══════════════════════════════════════════════════════
class EmployeeLeaveScreen extends StatefulWidget {
  const EmployeeLeaveScreen({super.key});
  @override State<EmployeeLeaveScreen> createState() => _LeaveState();
}
class _LeaveState extends State<EmployeeLeaveScreen> {
  List<LeaveModel> _leaves = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final svc = context.read<SupabaseService>();
      _leaves = await svc.fetchLeaves(employeeId: svc.currentUser!.id);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SectionHeader(
            title: 'Izin & Cuti',
            subtitle: 'Ajukan dan pantau status cuti Anda',
            action: ElevatedButton.icon(
              onPressed: () => _showForm(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Ajukan Cuti')),
          ),
          const SizedBox(height: 22),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _quota('Cuti Tahunan', 12,
                _leaves.where((l) => l.type == LeaveType.annual    && l.status == LeaveStatus.approved).fold(0, (s, l) => s + l.duration),
                AppColors.primary),
              const SizedBox(width: 12),
              _quota('Cuti Sakit', 14,
                _leaves.where((l) => l.type == LeaveType.sick      && l.status == LeaveStatus.approved).fold(0, (s, l) => s + l.duration),
                AppColors.accent),
              const SizedBox(width: 12),
              _quota('Cuti Melahirkan', 90,
                _leaves.where((l) => l.type == LeaveType.maternity && l.status == LeaveStatus.approved).fold(0, (s, l) => s + l.duration),
                const Color(0xFFEC4899)),
              const SizedBox(width: 12),
              _quota('Cuti Haid', 2,
                _leaves.where((l) => l.type == LeaveType.menstrual && l.status == LeaveStatus.approved).fold(0, (s, l) => s + l.duration),
                const Color(0xFFE879A0)),
              const SizedBox(width: 12),
              _quota('Cuti Berbayar', 5,
                _leaves.where((l) => l.type == LeaveType.paid      && l.status == LeaveStatus.approved).fold(0, (s, l) => s + l.duration),
                AppColors.success),
            ]),
          ),
          const SizedBox(height: 22),
          GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Riwayat Pengajuan', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 14),
            if (_leaves.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(30),
                child: Text('Belum ada pengajuan', style: TextStyle(color: AppColors.textMuted))))
            else
              ..._leaves.map((l) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.background, borderRadius: BorderRadius.circular(12),
                  border: Border(left: BorderSide(color: l.type.color, width: 4))),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      StatusBadge(label: l.type.label, color: l.type.color),
                      const SizedBox(width: 8),
                      Text('${l.duration} hari', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    ]),
                    const SizedBox(height: 6),
                    Text('${DateFormat("d MMM yyyy").format(l.startDate)} – ${DateFormat("d MMM yyyy").format(l.endDate)}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text(l.reason, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ])),
                  StatusBadge(label: l.status.label, color: l.status.color),
                ]),
              )),
          ])),
        ]),
      ),
    );
  }

  Widget _quota(String label, int total, int used, Color color) {
    final pct = total > 0 ? (used / total).clamp(0.0, 1.0) : 0.0;
    return Container(
      width: 180, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEF5))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('$used/$total hari', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          Text('${((1 - pct) * total).toInt()} sisa', style: TextStyle(fontSize: 12, color: color)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: pct, backgroundColor: color.withOpacity(0.15), color: color, minHeight: 8)),
      ]),
    );
  }

  void _showForm(BuildContext ctx) {
    final reasonCtrl = TextEditingController();
    LeaveType type = LeaveType.annual;
    DateTime? start, end;
    showDialog(
      context: ctx,
      builder: (dCtx) => StatefulBuilder(
        builder: (dCtx, setS) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 440, padding: const EdgeInsets.all(28),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Ajukan Cuti', style: Theme.of(ctx).textTheme.headlineSmall),
                IconButton(onPressed: () => Navigator.pop(dCtx), icon: const Icon(Icons.close)),
              ]),
              const SizedBox(height: 18),
              DropdownButtonFormField<LeaveType>(
                value: type,
                decoration: InputDecoration(labelText: 'Jenis Cuti',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                items: LeaveType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label))).toList(),
                onChanged: (v) => setS(() => type = v!),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: GestureDetector(
                  onTap: () async {
                    final d = await showDatePicker(context: ctx,
                      initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2027));
                    if (d != null) setS(() => start = d);
                  },
                  child: _dateBox(start, 'Mulai'),
                )),
                const SizedBox(width: 10),
                Expanded(child: GestureDetector(
                  onTap: () async {
                    final d = await showDatePicker(context: ctx,
                      initialDate: start ?? DateTime.now(),
                      firstDate: start ?? DateTime.now(), lastDate: DateTime(2027));
                    if (d != null) setS(() => end = d);
                  },
                  child: _dateBox(end, 'Selesai'),
                )),
              ]),
              const SizedBox(height: 12),
              TextField(controller: reasonCtrl, maxLines: 3,
                decoration: InputDecoration(labelText: 'Alasan',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 20),
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: () async {
                  if (start == null || end == null || reasonCtrl.text.isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                      content: Text('Lengkapi semua field!'), backgroundColor: AppColors.accent));
                    return;
                  }
                  final svc = context.read<SupabaseService>();
                  await svc.submitLeave(LeaveModel(
                    id: const Uuid().v4(), employeeId: svc.currentUser!.id,
                    employeeName: svc.currentUser!.name, type: type,
                    startDate: start!, endDate: end!, reason: reasonCtrl.text,
                    status: LeaveStatus.pending, submittedAt: DateTime.now(),
                  ));
                  Navigator.pop(dCtx);
                  if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                    content: Text('Pengajuan cuti berhasil dikirim!'), backgroundColor: AppColors.success));
                  await _load();
                },
                child: const Text('Kirim Pengajuan'),
              )),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _dateBox(DateTime? d, String hint) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE5E7EB)),
      borderRadius: BorderRadius.circular(12)),
    child: Row(children: [
      const Icon(Icons.calendar_today_outlined, size: 15, color: AppColors.textMuted),
      const SizedBox(width: 8),
      Text(d != null ? DateFormat('d MMM yyyy').format(d) : hint,
        style: TextStyle(fontSize: 13, color: d != null ? AppColors.textPrimary : AppColors.textMuted)),
    ]),
  );
}

// ══════════════════════════════════════════════════════
// SALARY
// ══════════════════════════════════════════════════════
class EmployeeSalaryScreen extends StatefulWidget {
  const EmployeeSalaryScreen({super.key});
  @override State<EmployeeSalaryScreen> createState() => _SalState();
}
class _SalState extends State<EmployeeSalaryScreen> {
  List<SalaryModel> _sal = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final svc = context.read<SupabaseService>();
      _sal = await svc.fetchSalaries(employeeId: svc.currentUser!.id);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _showDetail(BuildContext context, SalaryModel s) {
    showDialog(context: context, builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: double.infinity, padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Slip Gaji ${monthName(s.month)} ${s.year}',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              IconButton(onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close, color: Colors.white70)),
            ]),
            StatusBadge(label: s.status.label, color: Colors.white, bgColor: Colors.white.withOpacity(0.2)),
          ]),
        ),
        Padding(padding: const EdgeInsets.all(24), child: Column(children: [
          _row('Gaji Pokok',   formatCurrency(s.baseSalary), AppColors.textPrimary),
          _row('Tunjangan',    formatCurrency(s.allowance),  AppColors.textPrimary),
          if (s.bonus > 0) _row('Bonus', formatCurrency(s.bonus), AppColors.success),
          const Divider(height: 24),
          _row('Potongan',    '-${formatCurrency(s.deduction)}', AppColors.accent),
          _row('Pajak (PPh)', '-${formatCurrency(s.tax)}',       AppColors.warning),
          const Divider(height: 24),
          _row('Total Bruto', formatCurrency(s.grossSalary), AppColors.textPrimary, bold: true),
          _row('Total Neto',  formatCurrency(s.netSalary),   AppColors.primary,     bold: true, large: true),
          const Divider(height: 24),
          _row('Hari Kerja', '${s.workingDays} hari', AppColors.textSecondary),
          _row('Hari Hadir', '${s.presentDays} hari', AppColors.textSecondary),
          if (s.paidDate != null && s.paidDate!.isNotEmpty)
            _row('Tanggal Bayar', s.paidDate!, AppColors.success),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx),
            icon: const Icon(Icons.check, size: 18), label: const Text('Tutup'))),
        ])),
      ]),
    ));
  }

  Widget _row(String label, String value, Color color, {bool bold = false, bool large = false}) =>
    Padding(padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontSize: large ? 15 : 14, color: AppColors.textSecondary)),
        Text(value,  style: TextStyle(fontSize: large ? 16 : 14, color: color,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
      ]));

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SectionHeader(title: 'Slip Gaji Saya', subtitle: 'Riwayat penggajian Anda'),
          const SizedBox(height: 22),
          if (_sal.isNotEmpty) _latestCard(_sal.first),
          const SizedBox(height: 22),
          if (_sal.isEmpty)
            GlassCard(child: const Center(child: Padding(
              padding: EdgeInsets.all(40),
              child: Column(children: [
                Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.textMuted),
                SizedBox(height: 12),
                Text('Belum ada data slip gaji.\nHubungi HRD untuk informasi lebih lanjut.',
                  style: TextStyle(color: AppColors.textMuted), textAlign: TextAlign.center),
              ]))))
          else
            GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Riwayat Gaji', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text('Klik kartu untuk melihat detail', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 14),
              ..._sal.map((s) => GestureDetector(
                onTap: () => _showDetail(context, s),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEEEEF5))),
                  child: Row(children: [
                    Container(padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
                        borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.receipt_rounded, color: Colors.white, size: 20)),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${monthName(s.month)} ${s.year}',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      Text('Hadir: ${s.presentDays}/${s.workingDays} hari',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    ])),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(formatCurrency(s.netSalary),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.primary)),
                      const SizedBox(height: 4),
                      StatusBadge(label: s.status.label, color: s.status.color),
                    ]),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
                  ]),
                ),
              )),
            ])),
        ]),
      ),
    );
  }

  Widget _latestCard(SalaryModel s) => GestureDetector(
    onTap: () => _showDetail(context, s),
    child: Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF8B5CF6).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Gaji Terakhir', style: TextStyle(color: Colors.white70, fontSize: 13)),
          StatusBadge(label: s.status.label, color: Colors.white, bgColor: Colors.white.withOpacity(0.2)),
        ]),
        const SizedBox(height: 6),
        Text(formatCurrency(s.netSalary),
          style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w700)),
        Text('${monthName(s.month)} ${s.year}',
          style: const TextStyle(color: Colors.white70, fontSize: 13)),
        const Divider(color: Colors.white24, height: 28),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _top('Gaji Pokok', formatCurrency(s.baseSalary)),
          _top('Tunjangan',  formatCurrency(s.allowance)),
          _top('Bonus',      formatCurrency(s.bonus)),
          _top('Potongan',   '-${formatCurrency(s.deduction + s.tax)}'),
        ]),
        const SizedBox(height: 12),
        Center(child: Text('Tap untuk lihat detail →',
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12))),
      ]),
    ),
  );

  Widget _top(String l, String v) => Column(children: [
    Text(l, style: const TextStyle(color: Colors.white60, fontSize: 11)),
    const SizedBox(height: 4),
    Text(v, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
  ]);
}
