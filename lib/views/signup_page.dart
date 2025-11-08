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
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> signup() async {
    if (_isLoading) return;

    final email = _emailController.text;
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Le password non corrispondono"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!isPasswordSafe(password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Password troppo debole. Minimo 8 caratteri con 1 numero, 1 minuscola e 1 maiuscola."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.signUpWithPassword(email, password);

      // Check if signup was successful
      if (mounted && Supabase.instance.client.auth.currentSession != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Registrazione completata!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Registrazione fallita. Email già in uso o non valida."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
            ElevatedButton(
              onPressed: _isLoading ? null : signup,
              child: _isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text("Signup"),
            ),
          ],
        ),
      ),
    );
  }
}