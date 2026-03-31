import 'package:brew_shift/constants/app_constants.dart';
import 'package:brew_shift/index.dart';
import 'package:brew_shift/session/app_session.dart';
import 'package:brew_shift/theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase is only initialised for account registration and sign-in.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Load the signed-in user before the first screen is shown.
  final session = AppSession();
  await session.initialize();

  runApp(BrewShiftApp(session: session));
}

/// Root widget for the Brew Shift prototype.
class BrewShiftApp extends StatelessWidget {
  const BrewShiftApp({super.key, required this.session});

  final AppSession session;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppSession>.value(
      value: session,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: AppConstants.appTitle,
        theme: BrewShiftTheme.lightTheme(),
        initialRoute: HomePageWidget.routePath,
        routes: {
          HomePageWidget.routePath: (_) => const HomePageWidget(),
          RegisterPageWidget.routePath: (_) => const RegisterPageWidget(),
          EmployeePageWidget.routePath: (_) => const EmployeePageWidget(),
          ManagerPageWidget.routePath: (_) => const ManagerPageWidget(),
        },
      ),
    );
  }
}
