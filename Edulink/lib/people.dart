import 'package:flutter/material.dart';

class Mypeople extends StatefulWidget {
  const Mypeople({super.key});

  @override
  State<Mypeople> createState() => _MypeopleState();
}

class _MypeopleState extends State<Mypeople> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('people'),
        centerTitle: true,
      ),
    );
  }
}