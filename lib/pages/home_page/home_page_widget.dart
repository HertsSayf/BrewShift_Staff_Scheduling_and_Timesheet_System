import 'package:brew_shift/components/my_button.dart';
import 'package:brew_shift/components/my_textfield.dart';
import 'package:brew_shift/constants/app_constants.dart';
import 'package:brew_shift/session/app_session.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../employee_page/employee_page_widget.dart';
import '../manager_page/manager_page_widget.dart';
import '../register_page/register_page_widget.dart';

/// Login screen for the Brew Shift prototype.
class HomePageWidget extends StatefulWidget {
  const HomePageWidget({super.key});

  static const String routeName = 'HomePage';
  static const String routePath = '/';

  @override
  State<HomePageWidget> createState() => _HomePageWidgetState();
}

class _HomePageWidgetState extends State<HomePageWidget> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // If a user is already signed in, send them straight to their dashboard.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AppSession>().currentUser;
      if (user != null) {
        _navigateToRoleHome(user.isManager);
      }
    });
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final session = context.read<AppSession>();
    final success = await session.login(
      identifier: _identifierController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) {
      return;
    }

    setState(() => _isLoading = false);

    if (!success) {
      _showMessage('Login failed. Check your email and password.');
      return;
    }

    _navigateToRoleHome(session.currentUser?.isManager ?? false);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _navigateToRegisterPage() {
    Navigator.of(context).pushNamed(RegisterPageWidget.routePath);
  }

  void _navigateToRoleHome(bool isManager) {
    Navigator.of(context).pushReplacementNamed(
      isManager ? ManagerPageWidget.routePath : EmployeePageWidget.routePath,
    );
  }

  String? _requiredEmailValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter your email address.';
    }
    return null;
  }

  String? _requiredPasswordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Enter a password.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('${AppConstants.appTitle} Login'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Branding and page introduction.
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          AppConstants.logoPath,
                          height: 120,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Staff Timesheet and Scheduling',
                        style: textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Log in with your email address to clock in, clock out and check rota information.',
                        style: textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // Login form fields.
                      MyTextField(
                        controller: _identifierController,
                        labelText: 'Email',
                        prefixIcon: Icons.email_outlined,
                        validator: _requiredEmailValidator,
                      ),
                      const SizedBox(height: 16),
                      MyTextField(
                        controller: _passwordController,
                        labelText: 'Password',
                        prefixIcon: Icons.lock_outline,
                        obscureText: true,
                        enableToggle: true,
                        validator: _requiredPasswordValidator,
                      ),
                      const SizedBox(height: 20),

                      // Main action buttons.
                      MyButton(
                        text: 'Enter',
                        onTap: _handleLogin,
                        isLoading: _isLoading,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Don't have an account? Please register below.",
                        style: textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      MyButton(
                        text: 'Register New User',
                        onTap: _navigateToRegisterPage,
                        isOutlined: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
