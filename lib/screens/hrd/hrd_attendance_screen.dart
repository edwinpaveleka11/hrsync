import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../models/models.dart';

class HrdAttendanceScreen extends StatefulWidget {
  const HrdAttendanceScreen({super.key});
  @override State<HrdAttendanceScreen> createState() => _HrdAttendanceScreenState();
}

class _HrdAttendanceScreenState extends State<HrdAttendanceScreen> {
  DateTime _selectedDate = DateTime.now();
  List<UserModel> _employees = [];
  List<AttendanceModel> _dayAtts = [];
  Map<String, Map<String, int>> _monthlySummary = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final svc = context.read<SupabaseService>();
    final emps = await svc.fetchEmployees();
    final atts = await svc.fetchAttendances(date: _selectedDate);
    final summary = <String, Map<String, int>>{};
    for (final emp in emps) {
      summary[emp.id] = await svc.getAttendanceSummary(emp.id);
    }
    if (!mounted) return;
    setState(() { _employees = emps; _dayAtts = atts; _monthlySummary = summary; _loading = false; });
  }

  Future<void> _changeDate(DateTime date) async {
    setState(() { _selectedDate = date; _loading = true; });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final presentCount = _dayAtts.where((a) => a.status == AttendanceStatus.present || a.status == AttendanceStatus.late).length;
    final lateCount    = _dayAtts.where((a) => a.status == AttendanceStatus.late).length;
    final absentCount  = _employees.length - _dayAtts.length;

    return RefreshIndicator(
        onRefresh: () async { setState(() => _loading = true); await _load(); },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(28),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SectionHeader(title: 'Manajemen Absensi', subtitle: 'Pantau kehadiran seluruh karyawan'),
            const SizedBox(height: 24),

            // Date picker + quick stats
            Wrap(spacing: 12, runSpacing: 12, children: [
              InkWell(
                onTap: () async {
                  final d = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2024), lastDate: DateTime.now());
                  if (d != null) await _changeDate(d);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_selectedDate), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(width: 8),
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                  ]),
                ),
              ),
              _chip('$presentCount Hadir', AppColors.success),
              _chip('$absentCount Absen',  AppColors.accent),
              _chip('$lateCount Terlambat', AppColors.warning),
            ]),
            const SizedBox(height: 24),

            // Daily table
            GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Absensi ${DateFormat('d MMMM yyyy', 'id_ID').format(_selectedDate)}', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              if (_employees.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Belum ada data karyawan', style: TextStyle(color: AppColors.textMuted))))
              else
                SingleChildScrollView(scrollDirection: Axis.horizontal, child: _buildTable()),
            ])),
            const SizedBox(height: 24),

            // Monthly summary
            GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Rekap Kehadiran Bulanan', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text('Statistik total kehadiran semua karyawan', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 20),
              ..._employees.map((emp) => _monthlySummaryRow(emp)),
            ])),
          ]),
        ),
    );
  }

  Widget _chip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.3))),
    child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
  );

  Widget _buildTable() {
    return DataTable(
      columnSpacing: 20,
      headingRowColor: WidgetStateProperty.all(AppColors.surfaceVariant),
      columns: const [
        DataColumn(label: Text('Karyawan',   style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
        DataColumn(label: Text('Check In',   style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
        DataColumn(label: Text('Check Out',  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
        DataColumn(label: Text('Durasi',     style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
        DataColumn(label: Text('Status',     style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
      ],
      rows: _employees.map((emp) {
        final att = _dayAtts.where((a) => a.employeeId == emp.id).firstOrNull;
        return DataRow(cells: [
          DataCell(Row(children: [
            AvatarWidget(initials: emp.avatarInitials, size: 30),
            const SizedBox(width: 8),
            Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(emp.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              Text(emp.department, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ]),
          ])),
          DataCell(Text(att?.checkIn  ?? '-', style: const TextStyle(fontSize: 13))),
          DataCell(Text(att?.checkOut ?? '-', style: const TextStyle(fontSize: 13))),
          DataCell(Text(att != null ? '${att.workHours}j' : '-', style: const TextStyle(fontSize: 13))),
          DataCell(att != null
            ? StatusBadge(label: att.status.label, color: att.status.color)
            : StatusBadge(label: 'Absen', color: AppColors.accent)),
        ]);
      }).toList(),
    );
  }

  Widget _monthlySummaryRow(UserModel emp) {
    final stats = _monthlySummary[emp.id] ?? {'present': 0, 'late': 0, 'absent': 0};
    final total   = (stats['present']! + stats['late']! + stats['absent']!);
    final pct     = total > 0 ? ((stats['present']! + stats['late']!) / total) : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(children: [
        AvatarWidget(initials: emp.avatarInitials, size: 36),
        const SizedBox(width: 12),
        SizedBox(width: 130, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(emp.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis),
          Text(emp.position.isNotEmpty ? emp.position : emp.department, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ])),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${(pct * 100).toStringAsFixed(0)}% kehadiran', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            Row(children: [
              _mini('${stats['present']}', 'Hadir',    AppColors.success),
              const SizedBox(width: 8),
              _mini('${stats['late']}',    'Terlambat', AppColors.warning),
              const SizedBox(width: 8),
              _mini('${stats['absent']}',  'Absen',    AppColors.accent),
            ]),
          ]),
          const SizedBox(height: 6),
          ClipRRect(borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: pct, backgroundColor: const Color(0xFFEEEEF5),
              color: pct > 0.8 ? AppColors.success : AppColors.warning, minHeight: 8)),
        ])),
      ]),
    );
  }

  Widget _mini(String v, String l, Color c) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
    const SizedBox(width: 4),
    Text('$v $l', style: TextStyle(fontSize: 11, color: c, fontWeight: FontWeight.w600)),
  ]);
}
