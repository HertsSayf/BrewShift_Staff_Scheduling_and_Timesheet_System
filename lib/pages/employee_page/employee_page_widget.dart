import 'package:brew_shift/components/dashboard_header_card.dart';
import 'package:brew_shift/components/info_row.dart';
import 'package:brew_shift/components/my_button.dart';
import 'package:brew_shift/components/section_card.dart';
import 'package:brew_shift/models/app_models.dart';
import 'package:brew_shift/services/local_store.dart';
import 'package:brew_shift/session/app_session.dart';
import 'package:brew_shift/utils/app_formatters.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../home_page/home_page_widget.dart';

/// Employee dashboard for local attendance and rota viewing.
class EmployeePageWidget extends StatefulWidget {
  const EmployeePageWidget({super.key});

  static const String routeName = 'EmployeePage';
  static const String routePath = '/employee';

  @override
  State<EmployeePageWidget> createState() => _EmployeePageWidgetState();
}

class _EmployeePageWidgetState extends State<EmployeePageWidget> {
  final LocalStoreService _store = LocalStoreService.instance;

  TimesheetRecord? _todayRecord;
  List<RotaEntry> _upcomingRotas = <RotaEntry>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final user = context.read<AppSession>().currentUser;
    if (user == null) {
      _redirectToHome();
      return;
    }

    final todayRecord = await _store.getTodayRecordForUser(user.id);
    final upcomingRotas = await _store.getUpcomingRotasForUser(user.id);

    if (!mounted) {
      return;
    }

    setState(() {
      _todayRecord = todayRecord;
      _upcomingRotas = upcomingRotas;
      _loading = false;
    });
  }

  Future<void> _handleClockIn() async {
    final user = context.read<AppSession>().currentUser;
    if (user == null) {
      return;
    }

    final result = await _store.clockIn(user);
    if (!mounted) {
      return;
    }

    _showMessage(result.message);
    await _loadData();
  }

  Future<void> _handleClockOut() async {
    final user = context.read<AppSession>().currentUser;
    if (user == null) {
      return;
    }

    final result = await _store.clockOut(user);
    if (!mounted) {
      return;
    }

    _showMessage(result.message);
    await _loadData();
  }

  Future<void> _logout() async {
    await context.read<AppSession>().logout();
    if (!mounted) {
      return;
    }

    _redirectToHome(clearStack: true);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _redirectToHome({bool clearStack = true}) {
    if (!mounted) {
      return;
    }

    if (clearStack) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        HomePageWidget.routePath,
        (route) => false,
      );
      return;
    }

    Navigator.of(context).pushNamed(HomePageWidget.routePath);
  }

  Widget _buildTodayRecord() {
    if (_todayRecord == null) {
      return const Text('No attendance recorded yet for today.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InfoRow(
          label: 'Status',
          value: AppFormatters.prettyStatus(_todayRecord!.status),
        ),
        InfoRow(
          label: 'Clock in',
          value: AppFormatters.time(_todayRecord!.clockIn),
        ),
        InfoRow(
          label: 'Clock out',
          value: AppFormatters.time(_todayRecord!.clockOut),
        ),
        InfoRow(
          label: 'Worked time',
          value: AppFormatters.workedMinutes(_todayRecord!.workedMinutes),
        ),
      ],
    );
  }

  Widget _buildUpcomingRotas(BuildContext context) {
    if (_upcomingRotas.isEmpty) {
      return const Text('No rota entries available yet.');
    }

    return Column(
      children: _upcomingRotas.take(7).map((entry) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            child: Text(AppFormatters.dayNumber(entry.shiftDate)),
          ),
          title: Text(
            '${AppFormatters.shortDay(entry.shiftDate)} · ${entry.shiftLabel}',
          ),
          subtitle: Text(
            '${entry.shiftTimeRange}'
            '${entry.notes.isEmpty ? '' : '\n${entry.notes}'}',
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppSession>().currentUser;
    if (user == null) {
      return const Scaffold(body: SizedBox.shrink());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Dashboard'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Overview of the signed-in employee.
                  DashboardHeaderCard(
                    title: 'Welcome, ${user.fullName}',
                    lines: [
                      'Staff ID: ${user.staffId}',
                      'Today: ${AppFormatters.fullDay(DateTime.now())}',
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Main attendance actions.
                  Row(
                    children: [
                      Expanded(
                        child: MyButton(
                          text: 'Clock In',
                          icon: Icons.login,
                          onTap: _handleClockIn,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MyButton(
                          text: 'Clock Out',
                          icon: Icons.logout,
                          onTap: _handleClockOut,
                          isOutlined: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Local timesheet summary for the current day.
                  SectionCard(
                    title: "Today's Record",
                    child: _buildTodayRecord(),
                  ),
                  const SizedBox(height: 16),

                  // Upcoming rota entries stored on-device.
                  SectionCard(
                    title: 'My Upcoming Shifts',
                    child: _buildUpcomingRotas(context),
                  ),
                ],
              ),
            ),
    );
  }
}
