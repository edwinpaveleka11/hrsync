import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/supabase_service.dart';
import '../screens/auth/login_screen.dart';
import '../screens/hrd/hrd_shell.dart';
import '../screens/hrd/hrd_dashboard.dart';
import '../screens/hrd/employee_list_screen.dart';
import '../screens/hrd/hrd_attendance_screen.dart';
import '../screens/hrd/hrd_leave_screen.dart';
import '../screens/hrd/hrd_salary_screen.dart';
import '../screens/employee/employee_shell.dart';
import '../screens/employee/employee_dashboard.dart';
import '../screens/employee/employee_attendance_screen.dart';
import '../screens/employee/employee_leave_screen.dart';
import '../screens/employee/employee_salary_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) {
    final service = context.read<SupabaseService>();
    final isLoggedIn = service.isLoggedIn;
    final isLoginPage = state.matchedLocation == '/login';
    if (!isLoggedIn && !isLoginPage) return '/login';
    if (isLoggedIn && isLoginPage) {
      return service.isHRD ? '/hrd/dashboard' : '/employee/dashboard';
    }
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    ShellRoute(
      builder: (context, state, child) => HrdShell(child: child),
      routes: [
        GoRoute(path: '/hrd/dashboard',  builder: (_, __) => const HrdDashboard()),
        GoRoute(path: '/hrd/employees',  builder: (_, __) => const EmployeeListScreen()),
        GoRoute(path: '/hrd/attendance', builder: (_, __) => const HrdAttendanceScreen()),
        GoRoute(path: '/hrd/leaves',     builder: (_, __) => const HrdLeaveScreen()),
        GoRoute(path: '/hrd/salary',     builder: (_, __) => const HrdSalaryScreen()),
      ],
    ),
    ShellRoute(
      builder: (context, state, child) => EmployeeShell(child: child),
      routes: [
        GoRoute(path: '/employee/dashboard',  builder: (_, __) => const EmployeeDashboard()),
        GoRoute(path: '/employee/attendance', builder: (_, __) => const EmployeeAttendanceScreen()),
        GoRoute(path: '/employee/leaves',     builder: (_, __) => const EmployeeLeaveScreen()),
        GoRoute(path: '/employee/salary',     builder: (_, __) => const EmployeeSalaryScreen()),
      ],
    ),
  ],
);
