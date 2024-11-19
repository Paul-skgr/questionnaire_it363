import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:questionnaire_app/screens/authenticate/authenticate_screen.dart';
import 'package:questionnaire_app/screens/home/home_screen.dart';
import 'package:questionnaire_app/models/user.dart';

class SplashScreenWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AppUser?>(context);
    if (user == null) {
      return AuthenticateScreen();
    } else {
      return HomeScreen();
    }
  }
}