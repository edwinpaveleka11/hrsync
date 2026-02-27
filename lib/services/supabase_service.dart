import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class SupabaseService extends ChangeNotifier {
  final _sb = Supabase.instance.client;

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isHRD => _currentUser?.role == UserRole.hrd;

  // ─── AUTH ────────────────────────────────────────────────────────────────

  Future<void> init() async {
    final session = _sb.auth.currentSession;
    if (session != null) await _fetchCurrentUser(session.user.id);

    _sb.auth.onAuthStateChange.listen((data) async {
      if (data.event == AuthChangeEvent.signedIn && data.session != null) {
        await _fetchCurrentUser(data.session!.user.id);
      } else if (data.event == AuthChangeEvent.signedOut) {
        _currentUser = null;
        notifyListeners();
      }
    });
  }

  Future<void> _fetchCurrentUser(String uid) async {
    try {
      final row = await _sb.from('employees').select().eq('id', uid).single();
      _currentUser = UserModel.fromMap(row);
      notifyListeners();
    } catch (e) {
      debugPrint('_fetchCurrentUser error: $e');
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      final res = await _sb.auth
          .signInWithPassword(email: email.trim(), password: password.trim());
      if (res.user == null) return 'Login gagal, coba lagi.';
      await _fetchCurrentUser(res.user!.id);
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Terjadi kesalahan: $e';
    }
  }

  Future<void> logout() async {
    await _sb.auth.signOut();
    _currentUser = null;
    notifyListeners();
  }

  // ─── EMPLOYEES ───────────────────────────────────────────────────────────

  Future<List<UserModel>> fetchEmployees() async {
    try {
      final rows = await _sb
          .from('employees')
          .select()
          .eq('role', 'employee')
          .eq('is_active', true)
          .order('name');
      return rows.map<UserModel>((r) => UserModel.fromMap(r)).toList();
    } catch (e) {
      debugPrint('fetchEmployees error: $e');
      return [];
    }
  }

  Future<void> updateEmployeeBaseSalary(
      String employeeId, double baseSalary) async {
    await _sb
        .from('employees')
        .update({'base_salary': baseSalary}).eq('id', employeeId);
  }

  Future<void> addEmployee({
    required String name,
    required String email,
    required String password,
    required String department,
    required String position,
    required String phone,
    required double baseSalary,
  }) async {
    final res = await _sb.auth.admin.createUser(AdminUserAttributes(
      email: email,
      password: password,
      userMetadata: {'name': name, 'role': 'employee'},
    ));
    if (res.user == null) throw Exception('Gagal membuat akun');
    await _sb.from('employees').update({
      'name': name,
      'department': department,
      'position': position,
      'phone': phone,
      'base_salary': baseSalary,
      'join_date': DateTime.now().toIso8601String().substring(0, 10),
    }).eq('id', res.user!.id);
  }

  // ─── ATTENDANCE ──────────────────────────────────────────────────────────

  // FIX: Tidak pakai join *, employees(name) — ambil nama dari cache atau
  // lakukan dua query terpisah supaya RLS tidak bermasalah.
  Future<List<AttendanceModel>> fetchAttendances({
    String? employeeId,
    DateTime? date,
  }) async {
    try {
      // Build query tanpa join
      PostgrestFilterBuilder query = _sb.from('attendances').select();
      if (employeeId != null) query = query.eq('employee_id', employeeId);
      if (date != null)
        query = query.eq('date', date.toIso8601String().substring(0, 10));

      final rows = await query.order('date', ascending: false);

      // Resolve nama karyawan: kalau HRD, fetch semua; kalau karyawan pakai nama sendiri
      Map<String, String> nameMap = {};
      if (isHRD) {
        final emps = await fetchEmployees();
        for (final e in emps) nameMap[e.id] = e.name;
        // tambahkan HRD sendiri juga
        if (_currentUser != null)
          nameMap[_currentUser!.id] = _currentUser!.name;
      } else if (_currentUser != null) {
        nameMap[_currentUser!.id] = _currentUser!.name;
      }

      return rows.map<AttendanceModel>((r) {
        final empName = nameMap[r['employee_id']] ?? '';
        return AttendanceModel.fromMap({...r, 'employee_name': empName});
      }).toList();
    } catch (e) {
      debugPrint('fetchAttendances error: $e');
      return [];
    }
  }

  Future<bool> hasCheckedInToday(String employeeId) async {
    try {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final rows = await _sb
          .from('attendances')
          .select('id')
          .eq('employee_id', employeeId)
          .eq('date', today);
      return rows.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<void> checkIn(String employeeId) async {
    final now = DateTime.now();
    final status = (now.hour > 8 || (now.hour == 8 && now.minute > 0))
        ? 'late'
        : 'present';
    await _sb.from('attendances').upsert({
      'employee_id': employeeId,
      'date': now.toIso8601String().substring(0, 10),
      'check_in':
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      'status': status,
    });
  }

  Future<void> checkOut(String employeeId) async {
    final now = DateTime.now();
    final today = now.toIso8601String().substring(0, 10);
    await _sb
        .from('attendances')
        .update({
          'check_out':
              '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
        })
        .eq('employee_id', employeeId)
        .eq('date', today);
  }

  Future<Map<String, int>> getAttendanceSummary(String employeeId) async {
    try {
      final rows = await _sb
          .from('attendances')
          .select('status')
          .eq('employee_id', employeeId);
      return {
        'present': rows.where((r) => r['status'] == 'present').length,
        'late': rows.where((r) => r['status'] == 'late').length,
        'absent': rows.where((r) => r['status'] == 'absent').length,
        'leave': rows.where((r) => r['status'] == 'leave').length,
      };
    } catch (e) {
      return {'present': 0, 'late': 0, 'absent': 0, 'leave': 0};
    }
  }

  // ─── LEAVES ──────────────────────────────────────────────────────────────

  // FIX: Tidak pakai join supaya RLS tidak bermasalah bagi karyawan
  Future<List<LeaveModel>> fetchLeaves({
    String? employeeId,
    LeaveStatus? status,
  }) async {
    try {
      PostgrestFilterBuilder query = _sb.from('leaves').select();
      if (employeeId != null) query = query.eq('employee_id', employeeId);
      if (status != null) query = query.eq('status', status.name);

      final rows = await query.order('submitted_at', ascending: false);

      // Resolve nama karyawan
      Map<String, String> nameMap = {};
      if (isHRD) {
        final emps = await fetchEmployees();
        for (final e in emps) nameMap[e.id] = e.name;
        if (_currentUser != null)
          nameMap[_currentUser!.id] = _currentUser!.name;
      } else if (_currentUser != null) {
        nameMap[_currentUser!.id] = _currentUser!.name;
      }

      return rows.map<LeaveModel>((r) {
        final empName = nameMap[r['employee_id']] ?? '';
        return LeaveModel.fromMap({...r, 'employee_name': empName});
      }).toList();
    } catch (e) {
      debugPrint('fetchLeaves error: $e');
      return [];
    }
  }

  Future<void> submitLeave(LeaveModel leave) async {
    await _sb.from('leaves').insert({
      'employee_id': leave.employeeId,
      'type': leave.type.name,
      'start_date': leave.startDate.toIso8601String().substring(0, 10),
      'end_date': leave.endDate.toIso8601String().substring(0, 10),
      'reason': leave.reason,
      'status': 'pending',
    });
  }

  Future<void> updateLeaveStatus(String leaveId, LeaveStatus status) async {
    await _sb.from('leaves').update({
      'status': status.name,
      'approved_by': status == LeaveStatus.approved ? _currentUser?.id : null,
    }).eq('id', leaveId);
  }

  // ─── SALARIES ────────────────────────────────────────────────────────────

  Future<List<SalaryModel>> fetchSalaries({
    String? employeeId,
    int? month,
    int? year,
  }) async {
    try {
      PostgrestFilterBuilder query = _sb.from('salaries').select();
      if (employeeId != null) query = query.eq('employee_id', employeeId);
      if (month != null) query = query.eq('month', month);
      if (year != null) query = query.eq('year', year);

      final rows = await query.order('year', ascending: false);

      Map<String, String> nameMap = {};
      if (isHRD) {
        final emps = await fetchEmployees();
        for (final e in emps) nameMap[e.id] = e.name;
        if (_currentUser != null)
          nameMap[_currentUser!.id] = _currentUser!.name;
      } else if (_currentUser != null) {
        nameMap[_currentUser!.id] = _currentUser!.name;
      }

      return rows.map<SalaryModel>((r) {
        final empName = nameMap[r['employee_id']] ?? '';
        return SalaryModel.fromMap({...r, 'employee_name': empName});
      }).toList();
    } catch (e) {
      debugPrint('fetchSalaries error: $e');
      return [];
    }
  }

  /// Hitung hari kerja efektif dalam sebulan (Senin–Jumat)
  int _countWorkingDays(int month, int year) {
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    int count = 0;
    for (var d = firstDay;
        !d.isAfter(lastDay);
        d = d.add(const Duration(days: 1))) {
      if (d.weekday <= 5) count++;
    }
    return count;
  }

  Future<void> generateMonthlySalaries(int month, int year) async {
    final employees = await fetchEmployees();
    final workingDays = _countWorkingDays(month, year);

    final firstDate = '$year-${month.toString().padLeft(2, '0')}-01';
    final lastDate =
        DateTime(year, month + 1, 0).toIso8601String().substring(0, 10);

    for (final emp in employees) {
      final attRows = await _sb
          .from('attendances')
          .select('status')
          .eq('employee_id', emp.id)
          .gte('date', firstDate)
          .lte('date', lastDate);

      int presentDays = 0;
      int leaveDays = 0;
      int absentDays = 0;

      for (final r in attRows) {
        final s = r['status'] as String? ?? '';
        if (s == 'present' || s == 'late')
          presentDays++;
        else if (s == 'leave')
          leaveDays++;
        else if (s == 'absent') absentDays++;
      }

      final paidDays = presentDays + leaveDays;

      final gajiPerHari = workingDays > 0 ? emp.baseSalary / workingDays : 0.0;
      final adjustedBase = gajiPerHari * paidDays;
      final allowance = adjustedBase * 0.15;
      final grossSalary = adjustedBase + allowance;
      final deduction = grossSalary * 0.02;
      final tax = (grossSalary - deduction) * 0.05;

      // 🔥 Cek apakah sudah ada dan status paid
      final existing = await _sb
          .from('salaries')
          .select()
          .eq('employee_id', emp.id)
          .eq('month', month)
          .eq('year', year)
          .maybeSingle();

      if (existing != null && existing['status'] == 'paid') {
        // Jangan timpa kalau sudah dibayar
        continue;
      }

      await _sb.from('salaries').upsert({
        'employee_id': emp.id,
        'month': month,
        'year': year,
        'base_salary': double.parse(adjustedBase.toStringAsFixed(0)),
        'allowance': double.parse(allowance.toStringAsFixed(0)),
        'bonus': 0.0,
        'deduction': double.parse(deduction.toStringAsFixed(0)),
        'tax': double.parse(tax.toStringAsFixed(0)),
        'status': 'pending',
        'working_days': workingDays,
        'present_days': presentDays,
      }, onConflict: 'employee_id,month,year');
    }
  }

  Future<void> processSalary(String salaryId) async {
    await _sb.from('salaries').update({
      'status': 'paid',
      'paid_date': DateTime.now().toIso8601String().substring(0, 10),
    }).eq('id', salaryId);
  }

  // ─── DASHBOARD STATS ─────────────────────────────────────────────────────

  // FIX: Try-catch per query supaya satu kegagalan tidak block semua
  Future<Map<String, dynamic>> getDashboardStats() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final now = DateTime.now();

    int totalEmp = 0;
    int presentToday = 0;
    int pendingCount = 0;
    double totalSalary = 0;

    try {
      final res = await _sb
          .from('employees')
          .select('id')
          .eq('role', 'employee')
          .eq('is_active', true);
      totalEmp = res.length;
    } catch (e) {
      debugPrint('stats employees: $e');
    }

    try {
      final res =
          await _sb.from('attendances').select('status').eq('date', today);
      presentToday = res
          .where((r) => r['status'] == 'present' || r['status'] == 'late')
          .length;
    } catch (e) {
      debugPrint('stats attendance: $e');
    }

    try {
      final res = await _sb.from('leaves').select('id').eq('status', 'pending');
      pendingCount = res.length;
    } catch (e) {
      debugPrint('stats leaves: $e');
    }

    try {
      final res = await _sb
          .from('salaries')
          .select('base_salary,allowance,bonus,deduction,tax')
          .eq('month', now.month)
          .eq('year', now.year);
      totalSalary = res.fold<double>(0, (sum, r) {
        final gross = ((r['base_salary'] as num?) ?? 0) +
            ((r['allowance'] as num?) ?? 0) +
            ((r['bonus'] as num?) ?? 0);
        final net =
            gross - ((r['deduction'] as num?) ?? 0) - ((r['tax'] as num?) ?? 0);
        return sum + net;
      });
    } catch (e) {
      debugPrint('stats salary: $e');
    }

    return {
      'totalEmployees': totalEmp,
      'presentToday': presentToday,
      'absentToday': totalEmp - presentToday,
      'pendingLeaves': pendingCount,
      'totalSalaryThisMonth': totalSalary,
    };
  }
}
