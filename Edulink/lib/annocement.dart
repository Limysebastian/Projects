import 'package:flutter/material.dart';

class Myanncement extends StatefulWidget {
  const Myanncement({super.key});

  @override
  State<Myanncement> createState() => _MyanncementState();
}

class _MyanncementState extends State<Myanncement> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Anncement'),
        centerTitle: true,
      ),
    );
  }
}