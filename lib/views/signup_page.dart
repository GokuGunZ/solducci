import 'package:flutter/material.dart';
import 'package:solducci/service/auth_service.dart';
import 'package:solducci/ui_elements/solducci_logo.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
   final _authService = AuthService();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  void signup() async {
    final email = _emailController.text;
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password!=confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Passwords don't match")));
      return;
    }

    if (!isPasswordSafe(password)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Passwords is too weak. At least 8 char with 1 number and 1 lower and upper case.")));
      return;
    }
    try {
       _authService.signUpWithPassword(email, password);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
    if (Supabase.instance.client.auth.currentSession?.isExpired == null){
      return;
    }
    Navigator.pop(context);
  }

  bool isPasswordSafe(String password) {
    if (password.length < 8) {
      return false;
    }

    bool hasNumber = false;
    bool hasLower = false;
    bool hasUpper = false;

    for (var codeUnit in password.codeUnits) {
      String char = String.fromCharCode(codeUnit);

      if ('0123456789'.contains(char)) {
        hasNumber = true;
      } else if ('abcdefghijklmnopqrstuvwxyz'.contains(char)) {
        hasLower = true;
      } else if ('ABCDEFGHIJKLMNOPQRSTUVWXYZ'.contains(char)) {
        hasUpper = true;
      }

      // Optimization: if all are true, break early
      if (hasNumber && hasLower && hasUpper) {
        return true;
      }
    }

    return hasNumber && hasLower && hasUpper;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sign up page"),),
      body: Form(
        child: ListView(
          padding: EdgeInsets.symmetric(vertical: 15, horizontal: 125),
          children: [
            SizedBox(height: 20,),
            Center(
              child: SolducciLogo(),
            ),
            SizedBox(height: 80,),
            TextFormField(
              decoration: InputDecoration(label: Text("eMail")),
              controller: _emailController,
            ),
            SizedBox(height: 50,),
            TextFormField(
              decoration: InputDecoration(label: Text("Password"), suffixIcon: Icon(Icons.password)),
              obscureText: true,
              enableSuggestions: false,
              autocorrect: false,
              controller: _passwordController,
            ),
            SizedBox(height: 50,),
            TextFormField(
              decoration: InputDecoration(label: Text("Confirm Password"), suffixIcon: Icon(Icons.password)),
              obscureText: true,
              enableSuggestions: false,
              autocorrect: false,
              controller: _confirmPasswordController,
            ),
            SizedBox(height: 50,),
            ElevatedButton(onPressed: () {signup();}, child: Text("Signup")),
          ],
        ),
      ),
    );
  }
}