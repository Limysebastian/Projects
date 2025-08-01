import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Myapi extends StatefulWidget {
  const Myapi({super.key});

  @override
  State<Myapi> createState() => _MyapiState();
}

class _MyapiState extends State<Myapi> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(

    );
  }
}
class ApiService {
  static const String _baseUrl = 'http://192.168.1.14/Empetz/api/v1/';
  
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }}