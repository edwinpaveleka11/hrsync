import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;
  late AnimationController _ac;
  late Animation<double>  _fade;
  late Animation<Offset>  _slide;

  @override
  void initState() {
    super.initState();
    _ac    = AnimationController(duration: const Duration(milliseconds: 700), vsync: this);
    _fade  = CurvedAnimation(parent: _ac, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
               .animate(CurvedAnimation(parent: _ac, curve: Curves.easeOut));
    _ac.forward();
  }

  @override
  void dispose() { _ac.dispose(); _emailCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  Future<void> _login() async {
    setState(() { _loading = true; _error = null; });
    final service = context.read<SupabaseService>();
    final err = await service.login(_emailCtrl.text, _passCtrl.text);
    if (!mounted) return;
    if (err == null) {
      context.go(service.isHRD ? '/hrd/dashboard' : '/employee/dashboard');
    } else {
      setState(() { _loading = false; _error = err; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    return Scaffold(
      body: Row(children: [
        if (!isMobile) _leftPanel(),
        Expanded(child: Container(
          color: Colors.white,
          child: Center(child: FadeTransition(opacity: _fade, child: SlideTransition(position: _slide,
            child: SingleChildScrollView(padding: const EdgeInsets.all(40),
              child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: _form()))))),
        )),
      ]),
    );
  }

  Widget _leftPanel() => Container(
    width: 460,
    decoration: const BoxDecoration(gradient: AppColors.darkGradient),
    child: Stack(children: [
      Positioned(top: -60, left: -60, child: _circle(200, AppColors.primary.withOpacity(0.3))),
      Positioned(bottom: -80, right: -80, child: _circle(280, AppColors.primaryLight.withOpacity(0.2))),
      Padding(padding: const EdgeInsets.all(48), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _logo(),
        const Spacer(),
        Container(padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.1))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('🚀', style: TextStyle(fontSize: 36)),
            const SizedBox(height: 12),
            const Text('Kelola SDM Lebih Cerdas', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Sistem HR terintegrasi dengan Supabase untuk absensi, penggajian, dan manajemen cuti.', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13, height: 1.6)),
          ])),
        const SizedBox(height: 28),
        _feat(Icons.fingerprint, 'Absensi Digital Real-time'),
        const SizedBox(height: 12),
        _feat(Icons.account_balance_wallet_outlined, 'Penggajian Otomatis'),
        const SizedBox(height: 12),
        _feat(Icons.beach_access_outlined, 'Manajemen Izin & Cuti'),
        const SizedBox(height: 12),
        _feat(Icons.lock_outlined, 'Auth & RLS via Supabase'),
        const SizedBox(height: 40),
      ])),
    ]),
  );

  Widget _circle(double s, Color c) => Container(width: s, height: s, decoration: BoxDecoration(shape: BoxShape.circle, color: c));
  Widget _logo() => Row(children: [
    Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(12)),
      child: const Icon(Icons.people_alt_rounded, color: Colors.white, size: 22)),
    const SizedBox(width: 12),
    const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('HRSync', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
      Text('Powered by Supabase', style: TextStyle(color: Colors.white38, fontSize: 11)),
    ]),
  ]);
  Widget _feat(IconData icon, String txt) => Row(children: [
    Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.3), borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, color: AppColors.primaryLight, size: 15)),
    const SizedBox(width: 10),
    Text(txt, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
  ]);

  Widget _form() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('Selamat Datang 👋', style: Theme.of(context).textTheme.displayMedium),
    const SizedBox(height: 6),
    Text('Masuk ke dashboard HRSync Anda', style: Theme.of(context).textTheme.bodyMedium),
    const SizedBox(height: 36),

    // Info box
    Container(padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(child: Text('Gunakan akun yang sudah didaftarkan di Supabase Authentication.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.primary))),
      ])),
    const SizedBox(height: 28),

    Text('Email', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 14)),
    const SizedBox(height: 8),
    TextField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress,
      decoration: const InputDecoration(hintText: 'email@perusahaan.com', prefixIcon: Icon(Icons.email_outlined, size: 20))),
    const SizedBox(height: 18),

    Text('Password', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 14)),
    const SizedBox(height: 8),
    TextField(controller: _passCtrl, obscureText: _obscure, onSubmitted: (_) => _login(),
      decoration: InputDecoration(hintText: '••••••••', prefixIcon: const Icon(Icons.lock_outline, size: 20),
        suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20), onPressed: () => setState(() => _obscure = !_obscure)))),

    if (_error != null) ...[
      const SizedBox(height: 12),
      Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Row(children: [
          const Icon(Icons.error_outline, color: AppColors.accent, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.accent, fontSize: 13))),
        ])),
    ],
    const SizedBox(height: 28),

    SizedBox(width: double.infinity, height: 52,
      child: ElevatedButton(
        onPressed: _loading ? null : _login,
        child: _loading
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : const Text('Masuk', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      )),
    const SizedBox(height: 28),
    Center(child: Text('© 2026 HRSync • Powered by Supabase', style: Theme.of(context).textTheme.bodySmall)),
  ]);
}
