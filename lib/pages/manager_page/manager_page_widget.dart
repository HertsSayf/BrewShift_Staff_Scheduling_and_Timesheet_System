import 'package:brew_shift/components/dashboard_header_card.dart';
import 'package:brew_shift/components/my_button.dart';
import 'package:brew_shift/components/my_textfield.dart';
import 'package:brew_shift/components/section_card.dart';
import 'package:brew_shift/models/app_models.dart';
import 'package:brew_shift/services/local_store.dart';
import 'package:brew_shift/session/app_session.dart';
import 'package:brew_shift/utils/app_formatters.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../home_page/home_page_widget.dart';

/// Manager dashboard for viewing timesheets and creating rota entries.
class ManagerPageWidget extends StatefulWidget {
  const ManagerPageWidget({super.key});

  static const String routeName = 'ManagerPage';
  static const String routePath = '/manager';

  @override
  State<ManagerPageWidget> createState() => _ManagerPageWidgetState();
}

class _ManagerPageWidgetState extends State<ManagerPageWidget> {
  final LocalStoreService _store = LocalStoreService.instance;

  final _rotaFormKey = GlobalKey<FormState>();
  final _startController = TextEditingController();
  final _endController = TextEditingController();
  final _labelController = TextEditingController();
  final _notesController = TextEditingController();

  List<TimesheetRecord> _todayTimesheets = <TimesheetRecord>[];
  List<RotaEntry> _rotas = <RotaEntry>[];
  List<AppUser> _employees = <AppUser>[];

  AppUser? _selectedEmployee;
  DateTime? _selectedDate;
  bool _loading = true;
  bool _savingRota = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    _labelController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final user = context.read<AppSession>().currentUser;
    if (user == null || !user.isManager) {
      _redirectToHome();
      return;
    }

    final timesheets = await _store.getTodayTimesheets();
    final rotas = await _store.getAllUpcomingRotas();
    final employees = await _store.loadActiveEmployees();

    if (!mounted) {
      return;
    }

    setState(() {
      _todayTimesheets = timesheets;
      _rotas = rotas;
      _employees = employees;
      _selectedEmployee = employees.isNotEmpty ? employees.first : null;
      _selectedDate ??= DateTime.now();
      _loading = false;
    });
  }

  Future<void> _pickDate() async {
    final current = _selectedDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveRota() async {
    if (!_rotaFormKey.currentState!.validate()) {
      return;
    }

    final manager = context.read<AppSession>().currentUser;
    if (manager == null || !manager.isManager || _selectedEmployee == null) {
      return;
    }

    setState(() => _savingRota = true);

    await _store.addRotaEntry(
      manager: manager,
      employee: _selectedEmployee!,
      shiftDate: _selectedDate ?? DateTime.now(),
      startTimeText: _startController.text,
      endTimeText: _endController.text,
      shiftLabel: _labelController.text,
      notes: _notesController.text,
    );

    if (!mounted) {
      return;
    }

    setState(() => _savingRota = false);
    _startController.clear();
    _endController.clear();
    _labelController.clear();
    _notesController.clear();

    _showMessage('Rota entry saved.');
    await _loadData();
  }

  Future<void> _logout() async {
    await context.read<AppSession>().logout();
    if (!mounted) {
      return;
    }

    _redirectToHome();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _redirectToHome() {
    if (!mounted) {
      return;
    }

    Navigator.of(context).pushNamedAndRemoveUntil(
      HomePageWidget.routePath,
      (route) => false,
    );
  }

  String? _requiredFieldValidator(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter ${fieldName.toLowerCase()}.';
    }
    return null;
  }

  Widget _buildTodayTimesheets() {
    if (_todayTimesheets.isEmpty) {
      return const Text('No attendance records for today yet.');
    }

    return Column(
      children: _todayTimesheets.map((record) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.schedule),
          title: Text('${record.staffName} (${record.staffId})'),
          subtitle: Text(
            'In: ${AppFormatters.time(record.clockIn)} · '
            'Out: ${AppFormatters.time(record.clockOut)} · '
            'Status: ${AppFormatters.prettyStatus(record.status)}',
          ),
          trailing: Text(
            AppFormatters.workedMinutes(record.workedMinutes),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRotaForm() {
    return Form(
      key: _rotaFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<AppUser>(
            value: _selectedEmployee,
            decoration: const InputDecoration(labelText: 'Employee'),
            items: _employees.map((employee) {
              return DropdownMenuItem<AppUser>(
                value: employee,
                child: Text('${employee.fullName} (${employee.staffId})'),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedEmployee = value);
            },
            validator: (value) {
              if (value == null) {
                return 'Select an employee.';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          MyButton(
            text: _selectedDate == null
                ? 'Choose shift date'
                : AppFormatters.fullDay(_selectedDate!),
            icon: Icons.calendar_today,
            onTap: _pickDate,
            isOutlined: true,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: MyTextField(
                  controller: _startController,
                  labelText: 'Start time',
                  hintText: '09:00',
                  validator: (value) =>
                      _requiredFieldValidator(value, 'a start time'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MyTextField(
                  controller: _endController,
                  labelText: 'End time',
                  hintText: '17:00',
                  validator: (value) =>
                      _requiredFieldValidator(value, 'an end time'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          MyTextField(
            controller: _labelController,
            labelText: 'Shift label',
            hintText: 'Front of House',
            validator: (value) =>
                _requiredFieldValidator(value, 'a shift label'),
          ),
          const SizedBox(height: 12),
          MyTextField(
            controller: _notesController,
            labelText: 'Notes (optional)',
            minLines: 2,
            maxLines: 4,
          ),
          const SizedBox(height: 16),
          MyButton(
            text: 'Save Rota Entry',
            icon: Icons.save,
            onTap: _saveRota,
            isLoading: _savingRota,
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingRotas() {
    if (_rotas.isEmpty) {
      return const Text('No rota entries saved yet.');
    }

    return Column(
      children: _rotas.take(10).map((entry) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.event_note),
          title: Text('${entry.staffName} · ${entry.shiftLabel}'),
          subtitle: Text(
            '${AppFormatters.shortDay(entry.shiftDate)} · '
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
        title: const Text('Manager Dashboard'),
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
                  // Overview of the signed-in manager.
                  DashboardHeaderCard(
                    title: 'Welcome, ${user.fullName}',
                    lines: [
                      'Role: Manager · Staff ID: ${user.staffId}',
                      'Today: ${AppFormatters.fullDay(DateTime.now())}',
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Staff attendance summary for the current day.
                  SectionCard(
                    title: "Today's Timesheets",
                    child: _buildTodayTimesheets(),
                  ),
                  const SizedBox(height: 16),

                  // Form used to create local rota entries.
                  SectionCard(
                    title: 'Create Rota Entry',
                    child: _buildRotaForm(),
                  ),
                  const SizedBox(height: 16),

                  // Upcoming rota entries already saved locally.
                  SectionCard(
                    title: 'Upcoming Rotas',
                    child: _buildUpcomingRotas(),
                  ),
                ],
              ),
            ),
    );
  }
}
