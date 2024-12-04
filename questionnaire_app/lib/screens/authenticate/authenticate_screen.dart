import 'package:flutter/material.dart';
import 'package:questionnaire_app/common/constants.dart';
import 'package:questionnaire_app/common/loading.dart';
import 'package:questionnaire_app/services/authentication.dart';


class AuthenticateScreen extends StatefulWidget {
  @override
  _AuthenticateScreenState createState() => _AuthenticateScreenState();
}

class _AuthenticateScreenState extends State<AuthenticateScreen> {
  final AuthenticationService _auth = AuthenticationService();
  final _formKey = GlobalKey<FormState>();
  String error = '';
  bool loading = false;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool showSignIn = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void toggleView() {
    setState(() {
      _formKey.currentState?.reset();
      error = '';
      emailController.text = '';
      passwordController.text = '';
      showSignIn = !showSignIn;
    });
  }

  Future<void> _handleRegister(String email, String password) async {
    setState(() => loading = true);

    dynamic result = await _auth.registerWithEmailAndPassword(email, password);

    if (!mounted) return;

    if (result == "Email verification sent") {
      setState(() => loading = false);
      Navigator.of(context).pushReplacementNamed('/verify');
    } else if (result == null) {
      setState(() {
        loading = false;
        error = 'Failed to register. Please try again.';
      });
    }
  }

Future<void> _handleSignIn(String email, String password) async {
  setState(() => loading = true);

  var result = await _auth.signInWithEmailAndPassword(email, password);

  if (!mounted) return;

  if (result == null) {
    setState(() {
      loading = false;
      error = 'Invalid email or password.';
    });
  } else {
    bool isVerified = await _auth.isEmailVerified();

    if (!mounted) return;

    if (isVerified) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      setState(() {
        loading = false;
      });
    }
  }
}
  @override
  Widget build(BuildContext context) {
    return loading
        ? Loading()
        : Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.blueGrey,
              elevation: 0.0,
              title: Text(showSignIn
                  ? 'Sign in to the quiz platform'
                  : 'Register to quiz platform'),
              actions: <Widget>[
                TextButton.icon(
                  icon: Icon(
                    Icons.person,
                    color: Colors.white,
                  ),
                  label: Text(showSignIn ? 'Sign In' : "Register"),
                  onPressed: () => toggleView(),
                ),
              ],
            ),
            body: Container(
              padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 30.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: emailController,
                      decoration: textInputDecoration.copyWith(hintText: 'email'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Enter an email";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10.0),
                    TextFormField(
                      controller: passwordController,
                      decoration: textInputDecoration.copyWith(hintText: 'password'),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.length < 4) {
                          return "Enter a password with at least 4 characters";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10.0),
                    ElevatedButton(
                      child: Text(
                        showSignIn ? "Sign In" : "Register",
                        style: TextStyle(color: Colors.blue),
                      ),
                      onPressed: () async {
                        if (_formKey.currentState?.validate() ?? false) {
                          var email = emailController.text.trim();
                          var password = passwordController.text.trim();

                          if (showSignIn) {
                            await _handleSignIn(email, password);
                          } else {
                            await _handleRegister(email, password);
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 10.0),
                    Text(
                      error,
                      style: TextStyle(color: Colors.red, fontSize: 15.0),
                    ),
                  ],
                ),
              ),
            ),
          );
  }
}