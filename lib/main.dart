import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:material_ui/material_ui.dart';

import 'app_theme.dart';
import 'firebase_options.dart';
import 'pages/dashboard_page.dart';
import 'pages/login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseException? firebaseInitializationError;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (error) {
    firebaseInitializationError = error;
  }
  runApp(
    StudentInformationApp(
      firebaseInitializationError: firebaseInitializationError,
    ),
  );
}

class StudentInformationApp extends StatelessWidget {
  const StudentInformationApp({super.key, this.firebaseInitializationError});

  final FirebaseException? firebaseInitializationError;

  @override
  Widget build(BuildContext context) {
    final firebaseError = firebaseInitializationError;
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeMode,
      builder: (context, themeMode, child) => MaterialApp(
        title: 'Student Information App',
        debugShowCheckedModeBanner: false,
        theme: lightBlueTheme,
        darkTheme: darkBlueTheme,
        themeMode: themeMode,
        home: firebaseError == null
            ? StreamBuilder<User?>(
                stream: FirebaseAuth.instance.authStateChanges(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Scaffold(
                      body: Center(
                        child: Text(
                          'Unable to check sign-in status: ${snapshot.error}',
                        ),
                      ),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return snapshot.hasData
                      ? const DashboardPage()
                      : const LoginPage();
                },
              )
            : Scaffold(
                appBar: AppBar(title: const Text('Student Information App')),
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Could not connect to Firebase: '
                      '${firebaseError.message ?? firebaseError.code}',
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
