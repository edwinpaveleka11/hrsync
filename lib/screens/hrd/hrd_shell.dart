import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/supabase_service.dart';

import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class HrdShell extends StatelessWidget {
  final Widget child;
  const HrdShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 900;

    if (isMobile) {
      return _MobileShell(child: child);
    }
    return _DesktopShell(child: child);
  }
}

class _DesktopShell extends StatelessWidget {
  final Widget child;
  const _DesktopShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const HrdSidebar(),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _MobileShell extends StatelessWidget {
  final Widget child;
  const _MobileShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.sidebar,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.people_alt_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            const Text('HRSync', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: const Drawer(child: HrdSidebar()),
      body: child,
    );
  }
}

class HrdSidebar extends StatelessWidget {
  const HrdSidebar({super.key});

  static const _navItems = [
    _NavItem('/hrd/dashboard', Icons.dashboard_rounded, 'Dashboard'),
    _NavItem('/hrd/employees', Icons.people_rounded, 'Data Karyawan'),
    _NavItem('/hrd/attendance', Icons.fingerprint_rounded, 'Absensi'),
    _NavItem('/hrd/leaves', Icons.beach_access_rounded, 'Izin & Cuti'),
    _NavItem('/hrd/salary', Icons.account_balance_wallet_rounded, 'Penggajian'),
  ];

  @override
  Widget build(BuildContext context) {
    final service = context.watch<SupabaseService>();
    final currentRoute = GoRouterState.of(context).matchedLocation;

    return Container(
      width: 240,
      decoration: const BoxDecoration(gradient: AppColors.darkGradient),
      child: Column(
        children: [
          // Logo
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.people_alt_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('HRSync', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                    Text('HRD Panel', style: TextStyle(color: Colors.white38, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // User info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  AvatarWidget(initials: service.currentUser?.avatarInitials ?? 'HR', size: 36),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(service.currentUser?.name ?? '', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                        const Text('HR Manager', style: TextStyle(color: Colors.white38, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(alignment: Alignment.centerLeft,
              child: Text('MENU', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5))),
          ),
          const SizedBox(height: 8),

          // Nav items
          for (final item in _navItems)
            _NavTile(item: item, isActive: currentRoute.startsWith(item.route)),

          const Spacer(),
          Divider(color: Colors.white.withOpacity(0.1)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.logout_rounded, color: AppColors.accent, size: 18),
              ),
              title: const Text('Keluar', style: TextStyle(color: Colors.white70, fontSize: 14)),
              onTap: () async {
                await service.logout();
                if (context.mounted) context.go('/login');
              },
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final String route;
  final IconData icon;
  final String label;
  const _NavItem(this.route, this.icon, this.label);
}

class _NavTile extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  const _NavTile({required this.item, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.go(item.route),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: isActive ? AppColors.primaryGradient : null,
              color: isActive ? null : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: isActive ? [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))] : [],
            ),
            child: Row(
              children: [
                Icon(item.icon, color: isActive ? Colors.white : Colors.white38, size: 20),
                const SizedBox(width: 12),
                Text(item.label, style: TextStyle(
                  color: isActive ? Colors.white : Colors.white60,
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                )),
                if (isActive) ...[
                  const Spacer(),
                  Container(
                    width: 6, height: 6,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
