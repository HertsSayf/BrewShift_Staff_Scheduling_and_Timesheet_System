import 'package:brew_shift/components/my_button.dart';
import 'package:brew_shift/components/my_textfield.dart';
import 'package:brew_shift/constants/app_constants.dart';
import 'package:brew_shift/session/app_session.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../employee_page/employee_page_widget.dart';
import '../manager_page/manager_page_widget.dart';

/// Registration screen used to create staff or manager accounts.
///
/// Firebase handles the account creation, while rota and attendance data stay
/// local elsewhere in the prototype.
class RegisterPageWidget extends StatefulWidget {
  const RegisterPageWidget({super.key});

  static const String routeName = 'RegisterPage';
  static const String routePath = '/register';

  @override
  State<RegisterPageWidget> createState() => _RegisterPageWidgetState();
}

class _RegisterPageWidgetState extends State<RegisterPageWidget> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _staffIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedRole = 'employee';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _staffIdController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final session = context.read<AppSession>();
    final error = await session.registerUser(
      fullName: _nameController.text,
      staffId: _staffIdController.text,
      email: _emailController.text,
      password: _passwordController.text,
      role: _selectedRole,
    );

    if (!mounted) {
      return;
    }

    setState(() => _isLoading = false);

    if (error != null) {
      _showMessage(error);
      return;
    }

    _showMessage('Account created successfully.');
    _navigateToRoleHome();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _navigateToRoleHome() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      _selectedRole == 'manager'
          ? ManagerPageWidget.routePath
          : EmployeePageWidget.routePath,
      (route) => false,
    );
  }

  String? _requiredValidator(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter ${fieldName.toLowerCase()}.';
    }
    return null;
  }

  String? _emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter an email address.';
    }
    if (!value.contains('@')) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  String? _passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Enter a password.';
    }
    if (value.length < 6) {
      return 'Password should be at least 6 characters.';
    }
    return null;
  }

  String? _confirmPasswordValidator(String? value) {
    if (value != _passwordController.text) {
      return 'Passwords do not match.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register User')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Card(
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
                          height: 96,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Create a new staff or manager account',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Please pick your role, and fill in the details below to create a new account.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),

                      // Account details form.
                      DropdownButtonFormField<String>(
                        value: _selectedRole,
                        decoration: const InputDecoration(labelText: 'Role'),
                        items: const [
                          DropdownMenuItem(
                            value: 'employee',
                            child: Text('Employee'),
                          ),
                          DropdownMenuItem(
                            value: 'manager',
                            child: Text('Manager'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedRole = value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      MyTextField(
                        controller: _nameController,
                        labelText: 'Full name',
                        validator: (value) => _requiredValidator(value, 'a full name'),
                      ),
                      const SizedBox(height: 16),
                      MyTextField(
                        controller: _staffIdController,
                        labelText: 'Staff ID',
                        validator: (value) => _requiredValidator(value, 'a staff ID'),
                      ),
                      const SizedBox(height: 16),
                      MyTextField(
                        controller: _emailController,
                        labelText: 'Email',
                        keyboardType: TextInputType.emailAddress,
                        validator: _emailValidator,
                      ),
                      const SizedBox(height: 16),
                      MyTextField(
                        controller: _passwordController,
                        labelText: 'Password',
                        obscureText: true,
                        enableToggle: true,
                        validator: _passwordValidator,
                      ),
                      const SizedBox(height: 16),
                      MyTextField(
                        controller: _confirmPasswordController,
                        labelText: 'Confirm password',
                        obscureText: true,
                        enableToggle: true,
                        validator: _confirmPasswordValidator,
                      ),
                      const SizedBox(height: 24),

                      // Submit action.
                      MyButton(
                        text: 'Register',
                        onTap: _register,
                        isLoading: _isLoading,
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
