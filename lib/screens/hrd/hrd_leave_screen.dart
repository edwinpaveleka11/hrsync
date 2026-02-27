import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../models/models.dart';

class HrdLeaveScreen extends StatefulWidget {
  const HrdLeaveScreen({super.key});
  @override State<HrdLeaveScreen> createState() => _State();
}

class _State extends State<HrdLeaveScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<LeaveModel> _all = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });
    try {
      final leaves = await context.read<SupabaseService>().fetchLeaves();
      if (!mounted) return;
      setState(() { _all = leaves; _loading = false; });
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
        const Icon(Icons.error_outline_rounded, size: 56, color: AppColors.accent),
        const SizedBox(height: 16),
        const Text('Gagal memuat data cuti', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(_error!, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        const SizedBox(height: 24),
        ElevatedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Coba Lagi')),
      ]));
    }

    final pending  = _all.where((l) => l.status == LeaveStatus.pending).toList();
    final approved = _all.where((l) => l.status == LeaveStatus.approved).toList();
    final rejected = _all.where((l) => l.status == LeaveStatus.rejected).toList();

    return RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(title: 'Manajemen Izin & Cuti', subtitle: '${_all.length} total pengajuan'),
              const SizedBox(height: 22),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  StatCard(title: 'Total',     value: '${_all.length}',     subtitle: 'Semua pengajuan', icon: Icons.list_alt_rounded,       gradientColors: [AppColors.primary, AppColors.info]),
                  const SizedBox(width: 14),
                  StatCard(title: 'Menunggu', value: '${pending.length}',  subtitle: 'Perlu disetujui', icon: Icons.pending_actions_rounded, gradientColors: [AppColors.accentOrange, AppColors.warning]),
                  const SizedBox(width: 14),
                  StatCard(title: 'Disetujui',value: '${approved.length}', subtitle: 'Diterima',        icon: Icons.check_circle_rounded,   gradientColors: [AppColors.success, const Color(0xFF10B981)]),
                  const SizedBox(width: 14),
                  StatCard(title: 'Ditolak',  value: '${rejected.length}', subtitle: 'Ditolak',         icon: Icons.cancel_rounded,         gradientColors: [AppColors.accent, const Color(0xFFEF4444)]),
                ]),
              ),
              const SizedBox(height: 22),

              GlassCard(
                padding: EdgeInsets.zero,
                child: Column(children: [
                  Container(
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFEEEEF5)))),
                    child: TabBar(
                      controller: _tab,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textSecondary,
                      indicatorColor: AppColors.primary,
                      tabs: [
                        Tab(text: 'Menunggu (${pending.length})'),
                        Tab(text: 'Disetujui (${approved.length})'),
                        Tab(text: 'Ditolak (${rejected.length})'),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 520,
                    child: TabBarView(
                      controller: _tab,
                      children: [
                        _LeaveList(leaves: pending,  showActions: true,  onRefresh: _load),
                        _LeaveList(leaves: approved, showActions: false, onRefresh: _load),
                        _LeaveList(leaves: rejected, showActions: false, onRefresh: _load),
                      ],
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),
    );
  }
}

class _LeaveList extends StatelessWidget {
  final List<LeaveModel> leaves;
  final bool showActions;
  final VoidCallback onRefresh;
  const _LeaveList({required this.leaves, required this.showActions, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (leaves.isEmpty) {
      return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.beach_access_rounded, size: 48, color: AppColors.textMuted),
        SizedBox(height: 12),
        Text('Tidak ada pengajuan', style: TextStyle(color: AppColors.textMuted, fontSize: 15)),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(18),
      itemCount: leaves.length,
      itemBuilder: (ctx, i) => _LeaveCard(leave: leaves[i], showActions: showActions, onAction: onRefresh),
    );
  }
}

class _LeaveCard extends StatelessWidget {
  final LeaveModel leave;
  final bool showActions;
  final VoidCallback onAction;
  const _LeaveCard({required this.leave, required this.showActions, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final svc = context.read<SupabaseService>();
    final df  = DateFormat('d MMM yyyy', 'id_ID');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: leave.type.color, width: 4)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AvatarWidget(initials: leave.employeeName.split(' ').map((w) => w.isEmpty ? '' : w[0]).take(2).join(), size: 40),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(leave.employeeName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
            StatusBadge(label: leave.status.label, color: leave.status.color),
          ]),
          const SizedBox(height: 6),
          Wrap(spacing: 8, runSpacing: 4, children: [
            StatusBadge(label: leave.type.label, color: leave.type.color),
            Text('${df.format(leave.startDate)} – ${df.format(leave.endDate)}',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(8)),
              child: Text('${leave.duration} hari', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 6),
          Text(leave.reason, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          if (showActions) ...[
            const SizedBox(height: 12),
            Row(children: [
              _btn(context, 'Setujui', Icons.check_rounded, AppColors.success, () async {
                await svc.updateLeaveStatus(leave.id, LeaveStatus.approved);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cuti disetujui'), backgroundColor: AppColors.success));
                onAction();
              }),
              const SizedBox(width: 10),
              _btn(context, 'Tolak', Icons.close_rounded, AppColors.accent, () async {
                await svc.updateLeaveStatus(leave.id, LeaveStatus.rejected);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cuti ditolak'), backgroundColor: AppColors.accent));
                onAction();
              }),
            ]),
          ],
        ])),
      ]),
    );
  }

  Widget _btn(BuildContext ctx, String label, IconData icon, Color color, VoidCallback onTap) =>
    ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 15),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color, foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        minimumSize: Size.zero,
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
}
