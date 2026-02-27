import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';

// ====== STAT CARD ======
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final double width;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    this.width = 220,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}

// ====== STATUS BADGE ======
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color? bgColor;

  const StatusBadge({super.key, required this.label, required this.color, this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor ?? color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

// ====== SECTION HEADER ======
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;

  const SectionHeader({super.key, required this.title, this.subtitle, this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ],
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

// ====== AVATAR WIDGET ======
class AvatarWidget extends StatelessWidget {
  final String initials;
  final double size;
  final List<Color>? gradient;

  const AvatarWidget({super.key, required this.initials, this.size = 40, this.gradient});

  static const List<List<Color>> _colors = [
    [Color(0xFF6C3CE1), Color(0xFF4FACFE)],
    [Color(0xFFFF6B6B), Color(0xFFFF9F43)],
    [Color(0xFF26D0CE), Color(0xFF1A9E9C)],
    [Color(0xFFFF9F43), Color(0xFFFFD93D)],
    [Color(0xFF6C3CE1), Color(0xFFFF6B6B)],
  ];

  @override
  Widget build(BuildContext context) {
    final colorIdx = initials.codeUnitAt(0) % _colors.length;
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient ?? _colors[colorIdx],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: (_colors[colorIdx][0]).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Center(
        child: Text(initials, style: TextStyle(color: Colors.white, fontSize: size * 0.35, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

// ====== GLASS CARD ======
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  const GlassCard({super.key, required this.child, this.padding, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEEEEF5)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: child,
        ),
      ),
    );
  }
}

// ====== LEAVE TYPE BADGE ======
extension LeaveTypeExt on LeaveType {
  String get label {
    switch (this) {
      case LeaveType.annual:    return 'Cuti Tahunan';
      case LeaveType.sick:      return 'Cuti Sakit';
      case LeaveType.maternity: return 'Cuti Melahirkan';
      case LeaveType.menstrual: return 'Cuti Haid';
      case LeaveType.paid:      return 'Cuti Berbayar';
    }
  }
  Color get color {
    switch (this) {
      case LeaveType.annual:    return AppColors.primary;
      case LeaveType.sick:      return AppColors.accent;
      case LeaveType.maternity: return const Color(0xFFEC4899);
      case LeaveType.menstrual: return const Color(0xFFE879A0);
      case LeaveType.paid:      return AppColors.success;
    }
  }
}

extension LeaveStatusExt on LeaveStatus {
  String get label {
    switch (this) {
      case LeaveStatus.pending: return 'Menunggu';
      case LeaveStatus.approved: return 'Disetujui';
      case LeaveStatus.rejected: return 'Ditolak';
    }
  }
  Color get color {
    switch (this) {
      case LeaveStatus.pending: return AppColors.warning;
      case LeaveStatus.approved: return AppColors.success;
      case LeaveStatus.rejected: return AppColors.accent;
    }
  }
}

extension AttendanceStatusExt on AttendanceStatus {
  String get label {
    switch (this) {
      case AttendanceStatus.present: return 'Hadir';
      case AttendanceStatus.absent: return 'Absen';
      case AttendanceStatus.late: return 'Terlambat';
      case AttendanceStatus.leave: return 'Cuti';
      case AttendanceStatus.holiday: return 'Libur';
    }
  }
  Color get color {
    switch (this) {
      case AttendanceStatus.present: return AppColors.statusPresent;
      case AttendanceStatus.absent: return AppColors.statusAbsent;
      case AttendanceStatus.late: return AppColors.statusLate;
      case AttendanceStatus.leave: return AppColors.statusLeave;
      case AttendanceStatus.holiday: return AppColors.info;
    }
  }
}

extension SalaryStatusExt on SalaryStatus {
  String get label {
    switch (this) {
      case SalaryStatus.pending: return 'Menunggu';
      case SalaryStatus.processed: return 'Diproses';
      case SalaryStatus.paid: return 'Dibayar';
    }
  }
  Color get color {
    switch (this) {
      case SalaryStatus.pending: return AppColors.warning;
      case SalaryStatus.processed: return AppColors.info;
      case SalaryStatus.paid: return AppColors.success;
    }
  }
}

String formatCurrency(double amount) {
  return 'Rp ${NumberFormat('#,###', 'id_ID').format(amount)}';
}

String monthName(int month) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
  return months[month - 1];
}
