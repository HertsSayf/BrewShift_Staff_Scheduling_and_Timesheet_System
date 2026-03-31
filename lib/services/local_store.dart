import 'dart:convert';

import 'package:brew_shift/models/app_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Simple result returned after a clock-in or clock-out action.

class ClockActionResult {
  const ClockActionResult({required this.success, required this.message});

  final bool success;
  final String message;
}

/// Local data store for attendance and rota information.
///
/// The Brew Shift prototype keeps these workflows on-device so the demo can
/// show partial backend integration: Firebase handles account access, while
/// timesheets and rota entries remain local.

class LocalStoreService {
  LocalStoreService._();

  static final LocalStoreService instance = LocalStoreService._();

  static const String _usersKey = 'brew_shift_users';
  static const String _timesheetsKey = 'brew_shift_timesheets';
  static const String _rotasKey = 'brew_shift_rotas';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  // -------------------- shared storage helpers --------------------

  Future<List<Map<String, dynamic>>> _readCollection(String key) async {
    final prefs = await _prefs;
    final rawList = prefs.getStringList(key) ?? <String>[];
    return rawList
        .map((item) => jsonDecode(item) as Map<String, dynamic>)
        .toList();
  }

  Future<void> _writeCollection(
    String key,
    List<Map<String, dynamic>> items,
  ) async {
    final prefs = await _prefs;
    await prefs.setStringList(
      key,
      items.map((item) => jsonEncode(item)).toList(),
    );
  }

  // -------------------- local user data --------------------

  Future<List<AppUser>> loadUsers() async {
    final rawUsers = await _readCollection(_usersKey);
    return rawUsers.map(AppUser.fromMap).toList();
  }

  Future<void> saveUsers(List<AppUser> users) async {
    await _writeCollection(
      _usersKey,
      users.map((user) => user.toMap()).toList(),
    );
  }

  /// Keeps Firebase-authenticated users available inside the local prototype
  /// store so managers can assign rota entries using the same user id.

  Future<void> upsertUser(AppUser user) async {
    final users = await loadUsers();
    final index = users.indexWhere((existing) => existing.id == user.id);

    if (index >= 0) {
      users[index] = user;
    } else {
      users.add(user);
    }

    await saveUsers(users);
  }

  Future<List<AppUser>> loadActiveEmployees() async {
    final users = await loadUsers();
    return users.where((user) => user.isEmployee && user.isActive).toList()
      ..sort((a, b) => a.fullName.compareTo(b.fullName));
  }

  // -------------------- timesheet storage --------------------

  Future<List<TimesheetRecord>> loadTimesheets() async {
    final rawTimesheets = await _readCollection(_timesheetsKey);
    return rawTimesheets.map(TimesheetRecord.fromMap).toList();
  }

  Future<void> saveTimesheets(List<TimesheetRecord> timesheets) async {
    await _writeCollection(
      _timesheetsKey,
      timesheets.map((record) => record.toMap()).toList(),
    );
  }

  // -------------------- rota storage --------------------

  Future<List<RotaEntry>> loadRotas() async {
    final rawRotas = await _readCollection(_rotasKey);
    return rawRotas.map(RotaEntry.fromMap).toList();
  }

  Future<void> saveRotas(List<RotaEntry> rotas) async {
    await _writeCollection(
      _rotasKey,
      rotas.map((entry) => entry.toMap()).toList(),
    );
  }

  // -------------------- attendance actions --------------------

  Future<ClockActionResult> clockIn(AppUser user) async {
    final timesheets = await loadTimesheets();
    final today = _startOfDay(DateTime.now());
    final existingIndex = _findTodayRecordIndex(timesheets, user.id, today);

    if (existingIndex >= 0) {
      final existing = timesheets[existingIndex];
      if (existing.clockIn != null && existing.clockOut == null) {
        return const ClockActionResult(
          success: false,
          message: 'Shift already started for today.',
        );
      }
      if (existing.isComplete) {
        return const ClockActionResult(
          success: false,
          message: "Today's shift is already complete.",
        );
      }
    }

    final record = TimesheetRecord(
      id: '${user.id}_${today.toIso8601String().substring(0, 10)}',
      userId: user.id,
      staffId: user.staffId,
      staffName: user.fullName,
      date: today,
      clockIn: DateTime.now(),
      status: 'clocked_in',
    );

    if (existingIndex >= 0) {
      timesheets[existingIndex] = record;
    } else {
      timesheets.add(record);
    }

    await saveTimesheets(timesheets);
    return const ClockActionResult(success: true, message: 'Clock in recorded.');
  }

  Future<ClockActionResult> clockOut(AppUser user) async {
    final timesheets = await loadTimesheets();
    final now = DateTime.now();
    final today = _startOfDay(now);
    final existingIndex = _findTodayRecordIndex(timesheets, user.id, today);

    if (existingIndex < 0) {
      return const ClockActionResult(
        success: false,
        message: 'Clock in first before ending the shift.',
      );
    }

    final existing = timesheets[existingIndex];
    if (existing.clockIn == null) {
      return const ClockActionResult(
        success: false,
        message: 'Clock in first before ending the shift.',
      );
    }
    if (existing.clockOut != null) {
      return const ClockActionResult(
        success: false,
        message: 'Shift already clocked out.',
      );
    }

    final workedMinutes = now.difference(existing.clockIn!).inMinutes;
    timesheets[existingIndex] = existing.copyWith(
      clockOut: now,
      workedMinutes: workedMinutes < 0 ? 0 : workedMinutes,
      status: 'clocked_out',
    );

    await saveTimesheets(timesheets);
    return const ClockActionResult(
      success: true,
      message: 'Clock out recorded.',
    );
  }

  // -------------------- query helpers --------------------

  Future<TimesheetRecord?> getTodayRecordForUser(String userId) async {
    final timesheets = await loadTimesheets();
    final today = _startOfDay(DateTime.now());

    try {
      return timesheets.firstWhere(
        (record) => record.userId == userId && _isSameDay(record.date, today),
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<TimesheetRecord>> getTodayTimesheets() async {
    final timesheets = await loadTimesheets();
    final today = _startOfDay(DateTime.now());

    return timesheets.where((record) => _isSameDay(record.date, today)).toList()
      ..sort((a, b) {
        final aTime = a.clockIn ?? a.date;
        final bTime = b.clockIn ?? b.date;
        return bTime.compareTo(aTime);
      });
  }

  Future<List<RotaEntry>> getUpcomingRotasForUser(String userId) async {
    final rotas = await loadRotas();
    final today = _startOfDay(DateTime.now());

    return rotas
        .where(
          (entry) =>
              entry.userId == userId &&
              !entry.shiftDate.isBefore(today.subtract(const Duration(days: 1))),
        )
        .toList()
      ..sort((a, b) => a.shiftDate.compareTo(b.shiftDate));
  }

  Future<List<RotaEntry>> getAllUpcomingRotas() async {
    final rotas = await loadRotas();
    return rotas.toList()..sort((a, b) => a.shiftDate.compareTo(b.shiftDate));
  }

  Future<void> addRotaEntry({
    required AppUser manager,
    required AppUser employee,
    required DateTime shiftDate,
    required String startTimeText,
    required String endTimeText,
    required String shiftLabel,
    required String notes,
  }) async {
    final rotas = await loadRotas();

    rotas.add(
      RotaEntry(
        id: 'rota_${DateTime.now().microsecondsSinceEpoch}',
        userId: employee.id,
        staffName: employee.fullName,
        staffId: employee.staffId,
        shiftDate: _startOfDay(shiftDate),
        startTimeText: startTimeText.trim(),
        endTimeText: endTimeText.trim(),
        shiftLabel: shiftLabel.trim(),
        notes: notes.trim(),
        createdBy: manager.id,
      ),
    );

    await saveRotas(rotas);
  }

  int _findTodayRecordIndex(
    List<TimesheetRecord> timesheets,
    String userId,
    DateTime today,
  ) {
    return timesheets.indexWhere(
      (record) => record.userId == userId && _isSameDay(record.date, today),
    );
  }

  DateTime _startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
