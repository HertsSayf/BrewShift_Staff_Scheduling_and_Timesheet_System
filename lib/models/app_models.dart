import 'dart:convert';

/// Basic user profile used across the Brew Shift prototype.
class AppUser {
  AppUser({
    required this.id,
    required this.fullName,
    required this.staffId,
    required this.email,
    required this.password,
    required this.role,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String fullName;
  final String staffId;
  final String email;
  final String password;
  final String role;
  final bool isActive;
  final DateTime createdAt;

  bool get isManager => role.toLowerCase() == 'manager';
  bool get isEmployee => !isManager;

  AppUser copyWith({
    String? id,
    String? fullName,
    String? staffId,
    String? email,
    String? password,
    String? role,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      staffId: staffId ?? this.staffId,
      email: email ?? this.email,
      password: password ?? this.password,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'staffId': staffId,
      'email': email,
      'password': password,
      'role': role,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String,
      fullName: map['fullName'] as String,
      staffId: map['staffId'] as String,
      email: map['email'] as String,
      password: map['password'] as String? ?? '',
      role: map['role'] as String,
      isActive: (map['isActive'] as bool?) ?? true,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory AppUser.fromJson(String source) =>
      AppUser.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

/// Single attendance record for one member of staff on one day.
class TimesheetRecord {
  TimesheetRecord({
    required this.id,
    required this.userId,
    required this.staffId,
    required this.staffName,
    required this.date,
    this.clockIn,
    this.clockOut,
    this.workedMinutes = 0,
    this.status = 'not_started',
  });

  final String id;
  final String userId;
  final String staffId;
  final String staffName;
  final DateTime date;
  final DateTime? clockIn;
  final DateTime? clockOut;
  final int workedMinutes;
  final String status;

  bool get isComplete => clockIn != null && clockOut != null;

  TimesheetRecord copyWith({
    String? id,
    String? userId,
    String? staffId,
    String? staffName,
    DateTime? date,
    DateTime? clockIn,
    DateTime? clockOut,
    int? workedMinutes,
    String? status,
    bool clearClockOut = false,
  }) {
    return TimesheetRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      staffId: staffId ?? this.staffId,
      staffName: staffName ?? this.staffName,
      date: date ?? this.date,
      clockIn: clockIn ?? this.clockIn,
      clockOut: clearClockOut ? null : (clockOut ?? this.clockOut),
      workedMinutes: workedMinutes ?? this.workedMinutes,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'staffId': staffId,
      'staffName': staffName,
      'date': date.toIso8601String(),
      'clockIn': clockIn?.toIso8601String(),
      'clockOut': clockOut?.toIso8601String(),
      'workedMinutes': workedMinutes,
      'status': status,
    };
  }

  factory TimesheetRecord.fromMap(Map<String, dynamic> map) {
    return TimesheetRecord(
      id: map['id'] as String,
      userId: map['userId'] as String,
      staffId: map['staffId'] as String,
      staffName: map['staffName'] as String,
      date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
      clockIn: map['clockIn'] == null
          ? null
          : DateTime.tryParse(map['clockIn'] as String),
      clockOut: map['clockOut'] == null
          ? null
          : DateTime.tryParse(map['clockOut'] as String),
      workedMinutes: (map['workedMinutes'] as num?)?.toInt() ?? 0,
      status: (map['status'] as String?) ?? 'not_started',
    );
  }
}

/// Scheduled shift entry created by a manager for an employee.
class RotaEntry {
  RotaEntry({
    required this.id,
    required this.userId,
    required this.staffName,
    required this.staffId,
    required this.shiftDate,
    required this.startTimeText,
    required this.endTimeText,
    required this.shiftLabel,
    this.notes = '',
    required this.createdBy,
  });

  final String id;
  final String userId;
  final String staffName;
  final String staffId;
  final DateTime shiftDate;
  final String startTimeText;
  final String endTimeText;
  final String shiftLabel;
  final String notes;
  final String createdBy;

  String get shiftTimeRange => '$startTimeText - $endTimeText';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'staffName': staffName,
      'staffId': staffId,
      'shiftDate': shiftDate.toIso8601String(),
      'startTimeText': startTimeText,
      'endTimeText': endTimeText,
      'shiftLabel': shiftLabel,
      'notes': notes,
      'createdBy': createdBy,
    };
  }

  factory RotaEntry.fromMap(Map<String, dynamic> map) {
    return RotaEntry(
      id: map['id'] as String,
      userId: map['userId'] as String,
      staffName: map['staffName'] as String,
      staffId: map['staffId'] as String,
      shiftDate:
          DateTime.tryParse(map['shiftDate'] as String? ?? '') ?? DateTime.now(),
      startTimeText: map['startTimeText'] as String,
      endTimeText: map['endTimeText'] as String,
      shiftLabel: map['shiftLabel'] as String,
      notes: (map['notes'] as String?) ?? '',
      createdBy: map['createdBy'] as String,
    );
  }
}
