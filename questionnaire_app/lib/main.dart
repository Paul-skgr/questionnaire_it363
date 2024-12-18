import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:questionnaire_app/services/authentication.dart';
import 'package:questionnaire_app/models/user.dart';
import 'package:questionnaire_app/screens/splashscreen_wrapper.dart';
import 'package:questionnaire_app/screens/home/home_screen.dart';
import 'package:questionnaire_app/screens/authenticate/authenticate_screen.dart';
import 'package:questionnaire_app/screens/authenticate/verification_screen.dart';
import 'package:questionnaire_app/screens/results/historic_screen.dart';
import 'package:questionnaire_app/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamProvider<AppUser?>.value(
      value: AuthenticationService().user,
      initialData: null,
      catchError: (_, __) => null,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: SplashScreenWrapper(),
        routes: {
          '/home': (context) => HomeScreen(),
          '/authenticate': (context) => AuthenticateScreen(),
          '/verify': (context) => VerificationScreen(),
          '/history': (content) => const HistoricScreen(),
        },
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
      ),
    );
  }
}