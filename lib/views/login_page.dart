import 'package:flutter/material.dart';
import 'package:solducci/service/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _authService = AuthService();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void login() async {
    final email = _emailController.text;
    final password = _passwordController.text;

    try {
       _authService.signInWithPassword(email, password);
       Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login page"),),
      body: Form(
        child: ListView(
          padding: EdgeInsets.symmetric(vertical: 15, horizontal: 125),
          children: [
            SizedBox(height: 20,),
            Center(
              child: ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (bounds) => LinearGradient(colors: [
                      Colors.red,
                      Colors.pink,
                      Colors.purple,
                      Colors.deepPurple,
                      Colors.deepPurple,
                      Colors.indigo,
                      Colors.blue,
                      Colors.lightBlue,
                      Colors.cyan,
                      Colors.teal,
                      Colors.green,
                      Colors.lightGreen,
                      Colors.lime,
                      Colors.yellow,
                      Colors.amber,
                      Colors.orange,
                      Colors.deepOrange,]).createShader(
                      Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                    ),
                    child: Text("Solducci", style: TextStyle(fontSize: 40),),
                  ),
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
            ElevatedButton(onPressed: () {
              login();
              Navigator.pop(context);
            }, child: Text("Login")),

            SizedBox(height: 50,),
            ElevatedButton(
              onPressed: () async {
                Navigator.pushNamed(context, "/signupage");
                },
              child: Text("Register Here")),
          ],
        ),
      ),
    );
  }
}