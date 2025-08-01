import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:miniproject/home.dart';
import 'package:miniproject/register.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController UsernameController = TextEditingController();
  final TextEditingController PasswordController = TextEditingController();

  String? UsernameError;
  String? PasswordError;

  String? validateUsername(String Username) {
    if (RegExp(r'[!@#<>?":_~;[\]\\|=+(*&^%0-9-)]').hasMatch(Username)) {
      return 'Username must not contain special characters or numbers';
    }
    if (Username.isEmpty) {
      return 'username cannot be empty';
    }
    return null;
  }

  String? validatePassword(String Password) {
    if (Password.length < 6) {
      return 'password must be at least 6 characters long';
    }

    if (!RegExp(r'[A-Z]').hasMatch(Password)) {
      return 'password must be at least one upercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(Password)) {
      return 'password must be at least one number';
    }
    return null;
  }

  bool _obscureText = true;

 Future<void> senddata() async {
  final Url = Uri.parse("http://192.168.1.35/Empetz/api/v1/user/login");
  final response = await http.post(
    Url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      "userName": UsernameController.text.trim(),
      "password": PasswordController.text.trim(),
    }),
  );
  
  if (response.statusCode == 200 || response.statusCode == 201) {
    print("datapost successfully");
    print(response.body);
    final data = jsonDecode(response.body);
    final token = data['token'];
    final username = UsernameController.text.trim(); // Get the username from the controller

    if (token != null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('username', username); // Save the username
      print("token show ${token}");
      print("username saved: $username");
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Login successfully'))
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => Home()),
    );
  } else {
    print(response.statusCode);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Failed to Login"))
    );
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            ClipPath(
              clipper: WaveClipper(),
              child: Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.shade800,
                      const Color.fromARGB(255, 11, 24, 52)
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.shade900,
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: const Center(
                  child: Text(
                    "Empetz",
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Cursive',
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Welcome back",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  TextField(
                    controller: UsernameController,
                    decoration: InputDecoration(
                      labelText: "User name",
                      errorText: UsernameError,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        UsernameError = validateUsername(value);
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: PasswordController,
                    obscureText: _obscureText,
                    decoration: InputDecoration(
                      labelText: "Password",
                      errorText: PasswordError,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureText
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        PasswordError = validatePassword(value);
                      });
                    },
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          PasswordError =
                              validatePassword(PasswordController.text);
                        });
                        setState(() {
                          UsernameError =
                              validateUsername(UsernameController.text);
                        });

                        if (PasswordError == null && UsernameError == null) {
                          senddata();
                        }
                      },
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade900,
                              Color.fromARGB(255, 11, 24, 52)
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          alignment: Alignment.center,
                          child: const Text(
                            "Log in",
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an Account? "),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => Register()),
                          );
                        },
                        child: Text(
                          "Create Account",
                          style: TextStyle(
                            color: Colors.blue.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();

    path.lineTo(0, size.height * 0.8);

    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 1.0,
      size.width * 0.5,
      size.height * 0.9,
    );

    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.8,
      size.width,
      size.height * 0.9,
    );

    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
