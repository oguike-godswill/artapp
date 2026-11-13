import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'api.dart';
import 'auth.dart';
import 'screens/auth_screens.dart';
import 'screens/shell.dart';
import 'theme.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final api = ApiClient();
  final auth = AuthController(api)..bootstrap();
  // When the session ends (logout / expiry) drop any pushed screens.
  auth.addListener(() {
    if (auth.status == AuthStatus.signedOut) {
      navigatorKey.currentState?.popUntil((r) => r.isFirst);
    }
  });
  runApp(MultiProvider(
    providers: [
      Provider<ApiClient>.value(value: api),
      ChangeNotifierProvider<AuthController>.value(value: auth),
    ],
    child: const SolisApp(),
  ));
}

class SolisApp extends StatelessWidget {
  const SolisApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent));
    final status = context.select<AuthController, AuthStatus>((a) => a.status);
    return MaterialApp(
      title: 'Solis',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: Solis.theme(),
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: switch (status) {
          AuthStatus.unknown => const SplashScreen(key: ValueKey('splash')),
          AuthStatus.signedOut => const WelcomeScreen(key: ValueKey('welcome')),
          AuthStatus.signedIn => const AppShell(key: ValueKey('shell')),
        },
      ),
    );
  }
}
