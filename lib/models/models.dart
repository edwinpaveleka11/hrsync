// ============= USER MODEL =============
class UserModel {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String department;
  final String position;
  final String phone;
  final String joinDate;
  final double baseSalary;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.department,
    required this.position,
    required this.phone,
    required this.joinDate,
    required this.baseSalary,
  });

  String get avatarInitials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  factory UserModel.fromMap(Map<String, dynamic> m) => UserModel(
    id:         m['id'] as String,
    name:       m['name'] as String,
    email:      m['email'] as String,
    role:       UserRole.values.firstWhere((e) => e.name == m['role'], orElse: () => UserRole.employee),
    department: m['department'] as String? ?? '',
    position:   m['position']  as String? ?? '',
    phone:      m['phone']     as String? ?? '',
    joinDate:   m['join_date'] as String? ?? '',
    baseSalary: (m['base_salary'] as num?)?.toDouble() ?? 0,
  );
}

enum UserRole { hrd, employee }

// ============= ATTENDANCE MODEL =============
class AttendanceModel {
  final String id;
  final String employeeId;
  final String employeeName;
  final DateTime date;
  final String? checkIn;
  final String? checkOut;
  final AttendanceStatus status;
  final String? notes;

  AttendanceModel({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.date,
    this.checkIn,
    this.checkOut,
    required this.status,
    this.notes,
  });

  int get workHours {
    if (checkIn == null || checkOut == null) return 0;
    final ip = checkIn!.split(':');
    final op = checkOut!.split(':');
    final im = int.parse(ip[0]) * 60 + int.parse(ip[1]);
    final om = int.parse(op[0]) * 60 + int.parse(op[1]);
    return ((om - im) / 60).floor();
  }

  factory AttendanceModel.fromMap(Map<String, dynamic> m) => AttendanceModel(
    id:           m['id'] as String,
    employeeId:   m['employee_id'] as String,
    employeeName: m['employee_name'] as String? ?? '',
    date:         DateTime.parse(m['date'] as String),
    checkIn:      m['check_in']  as String?,
    checkOut:     m['check_out'] as String?,
    status:       AttendanceStatus.values.firstWhere(
                    (e) => e.name == m['status'], orElse: () => AttendanceStatus.absent),
    notes:        m['notes'] as String?,
  );
}

enum AttendanceStatus { present, absent, late, leave, holiday }

// ============= LEAVE MODEL =============
class LeaveModel {
  final String id;
  final String employeeId;
  final String employeeName;
  final LeaveType type;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final LeaveStatus status;
  final String? approvedBy;
  final DateTime submittedAt;

  LeaveModel({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.status,
    this.approvedBy,
    required this.submittedAt,
  });

  int get duration => endDate.difference(startDate).inDays + 1;

  factory LeaveModel.fromMap(Map<String, dynamic> m) => LeaveModel(
    id:           m['id'] as String,
    employeeId:   m['employee_id'] as String,
    employeeName: m['employee_name'] as String? ?? '',
    type:         LeaveType.values.firstWhere(
                    (e) => e.name == m['type'], orElse: () => LeaveType.annual),
    startDate:    DateTime.parse(m['start_date'] as String),
    endDate:      DateTime.parse(m['end_date']   as String),
    reason:       m['reason'] as String,
    status:       LeaveStatus.values.firstWhere(
                    (e) => e.name == m['status'], orElse: () => LeaveStatus.pending),
    approvedBy:   m['approved_by'] as String?,
    submittedAt:  DateTime.parse(m['submitted_at'] as String),
  );
}

enum LeaveType   { annual, sick, maternity, menstrual, paid }
enum LeaveStatus { pending, approved, rejected }

// ============= SALARY MODEL =============
class SalaryModel {
  final String id;
  final String employeeId;
  final String employeeName;
  final int month;
  final int year;
  final double baseSalary;
  final double allowance;
  final double bonus;
  final double deduction;
  final double tax;
  final SalaryStatus status;
  final String? paidDate;
  final int workingDays;
  final int presentDays;

  SalaryModel({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.month,
    required this.year,
    required this.baseSalary,
    this.allowance = 0,
    this.bonus     = 0,
    this.deduction = 0,
    this.tax       = 0,
    required this.status,
    this.paidDate,
    required this.workingDays,
    required this.presentDays,
  });

  double get grossSalary => baseSalary + allowance + bonus;
  double get netSalary   => grossSalary - deduction - tax;

  factory SalaryModel.fromMap(Map<String, dynamic> m) => SalaryModel(
    id:           m['id'] as String,
    employeeId:   m['employee_id'] as String,
    employeeName: m['employee_name'] as String? ?? '',
    month:        m['month'] as int,
    year:         m['year']  as int,
    baseSalary:   (m['base_salary'] as num).toDouble(),
    allowance:    (m['allowance']   as num?)?.toDouble() ?? 0,
    bonus:        (m['bonus']       as num?)?.toDouble() ?? 0,
    deduction:    (m['deduction']   as num?)?.toDouble() ?? 0,
    tax:          (m['tax']         as num?)?.toDouble() ?? 0,
    status:       SalaryStatus.values.firstWhere(
                    (e) => e.name == m['status'], orElse: () => SalaryStatus.pending),
    paidDate:     m['paid_date'] as String?,
    workingDays:  m['working_days'] as int? ?? 22,
    presentDays:  m['present_days'] as int? ?? 0,
  );
}

enum SalaryStatus { pending, processed, paid }
