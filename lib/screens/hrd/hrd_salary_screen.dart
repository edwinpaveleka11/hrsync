import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../models/models.dart';

// ─── Helpers ─────────────────────────────────────────────────────────────────

const _monthNames = [
  '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];

Color _statusColor(SalaryStatus s) {
  switch (s) {
    case SalaryStatus.paid:       return AppColors.success;
    case SalaryStatus.processed:  return AppColors.info;
    case SalaryStatus.pending:    return AppColors.accentOrange;
  }
}

IconData _statusIcon(SalaryStatus s) {
  switch (s) {
    case SalaryStatus.paid:       return Icons.check_circle_rounded;
    case SalaryStatus.processed:  return Icons.pending_actions_rounded;
    case SalaryStatus.pending:    return Icons.hourglass_top_rounded;
  }
}

extension SalaryStatusLabel on SalaryStatus {
  String get label {
    switch (this) {
      case SalaryStatus.paid:      return 'Dibayar';
      case SalaryStatus.processed: return 'Diproses';
      case SalaryStatus.pending:   return 'Pending';
    }
  }
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class HrdSalaryScreen extends StatefulWidget {
  const HrdSalaryScreen({super.key});

  @override
  State<HrdSalaryScreen> createState() => _HrdSalaryScreenState();
}

class _HrdSalaryScreenState extends State<HrdSalaryScreen> {
  int  _month     = DateTime.now().month;
  int  _year      = DateTime.now().year;
  List<SalaryModel> _list      = [];
  bool _loading   = true;
  bool _generating = false;
  String? _error;
  String  _search = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });
    try {
      final data = await context
          .read<SupabaseService>()
          .fetchSalaries(month: _month, year: _year);
      if (!mounted) return;
      setState(() { _list = data; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  Future<void> _generate() async {
    if (_list.isNotEmpty) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (dCtx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Generate Ulang?'),
          content: Text(
            'Data gaji ${_monthNames[_month]} $_year sudah ada.\n'
            'Generate ulang akan menimpa data yang belum dibayar.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dCtx).pop(false), child: const Text('Batal')),
            ElevatedButton(onPressed: () => Navigator.of(dCtx).pop(true), child: const Text('Ya, Generate')),
          ],
        ),
      );
      if (ok != true) return;
    }

    setState(() => _generating = true);
    try {
      await context.read<SupabaseService>().generateMonthlySalaries(_month, _year);
      await _load();
      if (mounted) _snack('Slip gaji berhasil di-generate 🎉', AppColors.success);
    } catch (e) {
      if (mounted) _snack('Error: $e', AppColors.accent);
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _payAll() async {
    final pending = _list.where((s) => s.status != SalaryStatus.paid).toList();
    if (pending.isEmpty) { _snack('Semua gaji sudah dibayar', AppColors.info); return; }

    final ok = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Bayar Semua?'),
        content: Text('${pending.length} slip gaji akan ditandai sebagai DIBAYAR.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dCtx).pop(false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () => Navigator.of(dCtx).pop(true),
            child: const Text('Bayar Semua'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _loading = true);
    final svc = context.read<SupabaseService>();
    for (final s in pending) await svc.processSalary(s.id);
    await _load();
    if (mounted) _snack('${pending.length} slip gaji berhasil dibayar ✓', AppColors.success);
  }

  void _snack(String msg, Color color) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ),
  );

  void _showDetail(SalaryModel s) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SalaryDetailSheet(salary: s),
  );

  List<SalaryModel> get _filtered => _search.isEmpty
      ? _list
      : _list.where((s) => s.employeeName.toLowerCase().contains(_search.toLowerCase())).toList();

  // ─────────────────────────────────────────────────────── BUILD ───────────

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                  children: [
                    _buildPageHeader(),
                    const SizedBox(height: 20),
                    _buildMonthSelector(),
                    const SizedBox(height: 20),
                    if (_list.isNotEmpty) ...[
                      _buildSummaryCards(),
                      const SizedBox(height: 20),
                      _buildSearchBar(),
                      const SizedBox(height: 16),
                    ],
                    _buildSalaryList(),
                  ],
                ),
    );
  }

  Widget _buildError() => ListView(
    children: [
      const SizedBox(height: 120),
      const Icon(Icons.error_outline_rounded, size: 64, color: AppColors.accent),
      const SizedBox(height: 16),
      const Center(child: Text('Gagal memuat data gaji',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
      const SizedBox(height: 8),
      Center(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 32),
          child: SelectableText(_error!, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)))),
      const SizedBox(height: 24),
      Center(child: ElevatedButton.icon(
          onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Coba Lagi'))),
    ],
  );

  Widget _buildPageHeader() {
    final unpaid = _list.where((s) => s.status != SalaryStatus.paid).length;
    return Row(
      children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Penggajian',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          if (_list.isNotEmpty)
            Text('$unpaid slip belum dibayar',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ])),
        const SizedBox(width: 8),
        if (_list.any((s) => s.status != SalaryStatus.paid))
          OutlinedButton.icon(
            onPressed: _payAll,
            icon: const Icon(Icons.payments_outlined, size: 16),
            label: const Text('Bayar Semua'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.success,
              side: const BorderSide(color: AppColors.success),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: _generating ? null : _generate,
          icon: _generating
              ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.auto_awesome_rounded, size: 16),
          label: const Text('Generate'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthSelector() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFEEEEF5)),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Row(children: [
      const Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 20),
      const SizedBox(width: 10),
      const Text('Periode Gaji', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      const Spacer(),
      _NavBtn(icon: Icons.chevron_left_rounded, onTap: () {
        setState(() { if (_month == 1) { _month = 12; _year--; } else _month--; });
        _load();
      }),
      const SizedBox(width: 8),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Text('${_monthNames[_month]} $_year',
          key: ValueKey('$_month-$_year'),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
      ),
      const SizedBox(width: 8),
      _NavBtn(icon: Icons.chevron_right_rounded, onTap: () {
        final now = DateTime.now();
        if (_year < now.year || (_year == now.year && _month < now.month)) {
          setState(() { if (_month == 12) { _month = 1; _year++; } else _month++; });
          _load();
        }
      }),
    ]),
  );

  Widget _buildSummaryCards() {
    final totalBruto = _list.fold<double>(0, (s, i) => s + i.grossSalary);
    final totalNeto  = _list.fold<double>(0, (s, i) => s + i.netSalary);
    final paidCount  = _list.where((s) => s.status == SalaryStatus.paid).length;
    final paidTotal  = _list.where((s) => s.status == SalaryStatus.paid)
        .fold<double>(0, (s, i) => s + i.netSalary);

    return Row(children: [
      Expanded(child: _SummaryCard(label: 'Total Bruto', value: formatCurrency(totalBruto),
          icon: Icons.account_balance_wallet_rounded, gradient: AppColors.primaryGradient)),
      const SizedBox(width: 12),
      Expanded(child: _SummaryCard(label: 'Total Neto', value: formatCurrency(totalNeto),
          icon: Icons.payments_rounded, gradient: AppColors.successGradient)),
      const SizedBox(width: 12),
      Expanded(child: _SummaryCard(label: 'Dibayar ($paidCount)', value: formatCurrency(paidTotal),
          icon: Icons.check_circle_rounded,
          gradient: const LinearGradient(colors: [Color(0xFFFF9F43), Color(0xFFFFD93D)]))),
    ]);
  }

  Widget _buildSearchBar() => TextField(
    onChanged: (v) => setState(() => _search = v),
    decoration: InputDecoration(
      hintText: 'Cari nama karyawan…',
      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
      suffixIcon: _search.isNotEmpty
          ? IconButton(icon: const Icon(Icons.clear_rounded, size: 18),
              onPressed: () => setState(() => _search = ''))
          : null,
      filled: true, fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFEEEEF5))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFEEEEF5))),
    ),
  );

  Widget _buildSalaryList() {
    if (_list.isEmpty) {
      return _EmptyState(
        icon: Icons.receipt_long_rounded,
        title: 'Belum ada data gaji',
        subtitle: 'Klik "Generate" untuk membuat slip gaji\n${_monthNames[_month]} $_year',
      );
    }

    final items = _filtered;
    if (items.isEmpty) {
      return const _EmptyState(
        icon: Icons.search_off_rounded,
        title: 'Karyawan tidak ditemukan',
        subtitle: 'Coba kata kunci lain',
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('${items.length} Karyawan',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textSecondary)),
      const SizedBox(height: 12),
      ...items.map((s) => _SalaryCard(
        salary: s,
        onTap: () => _showDetail(s),
        onPay: s.status != SalaryStatus.paid
            ? () async {
                await context.read<SupabaseService>().processSalary(s.id);
                await _load();
                if (mounted) _snack('Gaji ${s.employeeName} berhasil dibayar ✓', AppColors.success);
              }
            : null,
      )),
    ]);
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _NavBtn extends StatelessWidget {
  const _NavBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap, borderRadius: BorderRadius.circular(8),
    child: Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, size: 18, color: AppColors.primary),
    ),
  );
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.label, required this.value, required this.icon, required this.gradient});
  final String label, value;
  final IconData icon;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: gradient,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: Colors.white.withOpacity(0.9), size: 18),
      const SizedBox(height: 8),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11)),
    ]),
  );
}

class _SalaryCard extends StatelessWidget {
  const _SalaryCard({required this.salary, required this.onTap, this.onPay});
  final SalaryModel salary;
  final VoidCallback onTap;
  final VoidCallback? onPay;

  String _initials(String name) {
    final p = name.trim().split(' ');
    if (p.length >= 2) return '${p[0][0]}${p[1][0]}'.toUpperCase();
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final s      = salary;
    final ratio  = s.workingDays > 0 ? s.presentDays / s.workingDays : 0.0;
    final attPct = (ratio * 100).round();
    final attColor = attPct >= 90 ? AppColors.success : attPct >= 70 ? AppColors.accentOrange : AppColors.accent;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEEEEF5)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(width: 44, height: 44,
                decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(12)),
                child: Center(child: Text(_initials(s.employeeName),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.employeeName,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Row(children: [
                  _StatusPill(status: s.status),
                  const SizedBox(width: 8),
                  Icon(Icons.access_time_rounded, size: 12, color: attColor),
                  const SizedBox(width: 3),
                  Text('${s.presentDays}/${s.workingDays} hari ($attPct%)',
                      style: TextStyle(fontSize: 11, color: attColor, fontWeight: FontWeight.w500)),
                ]),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(formatCurrency(s.netSalary),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
                const Text('neto', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ]),
            ]),
          ),
          // Attendance progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio.clamp(0.0, 1.0),
                backgroundColor: attColor.withOpacity(0.12),
                color: attColor, minHeight: 4,
              ),
            ),
          ),
          // Action row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(children: [
              const Icon(Icons.info_outline_rounded, size: 13, color: AppColors.textMuted),
              const SizedBox(width: 4),
              const Text('Tap untuk detail', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
              const Spacer(),
              if (onPay != null)
                GestureDetector(
                  onTap: onPay,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: AppColors.successGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Bayar Sekarang',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                )
              else
                const Row(children: [
                  Icon(Icons.check_circle_rounded, size: 14, color: AppColors.success),
                  SizedBox(width: 4),
                  Text('Lunas', style: TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w600)),
                ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final SalaryStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(_statusIcon(status), size: 10, color: color),
        const SizedBox(width: 4),
        Text(SalaryStatusLabel(status).label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title, subtitle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 60),
    child: Column(children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(20)),
        child: Icon(icon, size: 48, color: AppColors.primary.withOpacity(0.5)),
      ),
      const SizedBox(height: 16),
      Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.textPrimary)),
      const SizedBox(height: 6),
      Text(subtitle, textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
    ]),
  );
}

// ─── Detail Bottom Sheet ─────────────────────────────────────────────────────

class _SalaryDetailSheet extends StatelessWidget {
  const _SalaryDetailSheet({required this.salary});
  final SalaryModel salary;

  String _initials(String name) {
    final p = name.trim().split(' ');
    if (p.length >= 2) return '${p[0][0]}${p[1][0]}'.toUpperCase();
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final s        = salary;
    final attPct   = s.workingDays > 0 ? (s.presentDays / s.workingDays * 100).round() : 0;
    final attColor = attPct >= 90 ? AppColors.success : attPct >= 70 ? AppColors.accentOrange : AppColors.accent;
    final absentDays = (s.workingDays - s.presentDays).clamp(0, s.workingDays);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (ctx, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Container(width: 48, height: 48,
                  decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(14)),
                  child: Center(child: Text(_initials(s.employeeName),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17)))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.employeeName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: AppColors.textPrimary)),
                Text('${_monthNames[s.month]} ${s.year}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ])),
              _StatusPill(status: s.status),
            ]),
          ),
          const SizedBox(height: 16),
          Expanded(child: ListView(controller: ctrl, padding: const EdgeInsets.symmetric(horizontal: 20), children: [
            // Kehadiran
            _DetailSection(title: 'Kehadiran', color: attColor, icon: Icons.bar_chart_rounded, children: [
              _DetailRow('Hari Kerja Efektif', '${s.workingDays} hari'),
              _DetailRow('Hadir (termasuk terlambat)', '${s.presentDays} hari'),
              _DetailRow('Alpha / Tidak Hadir', '$absentDays hari', valueColor: AppColors.accent),
              _DetailRow('Persentase Kehadiran', '$attPct%', valueColor: attColor, isBold: true),
            ]),
            const SizedBox(height: 16),
            // Pendapatan
            _DetailSection(title: 'Pendapatan', color: AppColors.primary, icon: Icons.trending_up_rounded, children: [
              _DetailRow('Gaji Pokok', formatCurrency(s.baseSalary),
                  isBold: true, hint: 'Sudah disesuaikan kehadiran ($attPct%)'),
              const Divider(height: 16),
              _DetailRow('Tunjangan Tetap (15%)', formatCurrency(s.allowance)),
              _DetailRow('Bonus', formatCurrency(s.bonus)),
              const Divider(height: 16),
              _DetailRow('Total Bruto', formatCurrency(s.grossSalary),
                  isBold: true, valueColor: AppColors.primary),
            ]),
            const SizedBox(height: 16),
            // Potongan
            _DetailSection(title: 'Potongan', color: AppColors.accent, icon: Icons.remove_circle_outline_rounded, children: [
              _DetailRow('BPJS & Potongan (2%)', '– ${formatCurrency(s.deduction)}',
                  valueColor: AppColors.accent),
              _DetailRow('PPh 21 (5%)', '– ${formatCurrency(s.tax)}',
                  valueColor: AppColors.accent),
              const Divider(height: 16),
              _DetailRow('Total Potongan', '– ${formatCurrency(s.deduction + s.tax)}',
                  isBold: true, valueColor: AppColors.accent),
            ]),
            const SizedBox(height: 16),
            // Neto box
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 16, offset: const Offset(0, 4))],
              ),
              child: Row(children: [
                const Icon(Icons.payments_rounded, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Gaji Diterima (Neto)',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                  Text(formatCurrency(s.netSalary),
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                ])),
              ]),
            ),
            if (s.paidDate != null) ...[
              const SizedBox(height: 12),
              Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.success),
                const SizedBox(width: 6),
                Text('Dibayar pada ${s.paidDate}',
                    style: const TextStyle(fontSize: 12, color: AppColors.success)),
              ])),
            ],
            const SizedBox(height: 24),
          ])),
        ]),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.color, required this.icon, required this.children});
  final String title;
  final Color color;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 14, color: color)),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: color)),
      ]),
      const SizedBox(height: 12),
      ...children,
    ]),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value, {this.isBold = false, this.valueColor, this.hint});
  final String label, value;
  final bool isBold;
  final Color? valueColor;
  final String? hint;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(
          fontSize: isBold ? 13 : 12,
          fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
          color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
        )),
        if (hint != null) Text(hint!, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
      ])),
      Text(value, style: TextStyle(
        fontSize: isBold ? 14 : 13,
        fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
        color: valueColor ?? (isBold ? AppColors.textPrimary : AppColors.textSecondary),
      )),
    ]),
  );
}