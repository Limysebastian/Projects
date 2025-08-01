import 'package:flutter/material.dart';

class Myupload extends StatefulWidget {
  const Myupload({super.key});

  @override
  State<Myupload> createState() => _MyuploadState();
}

class _MyuploadState extends State<Myupload> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('upload'),
        centerTitle: true,
      ),
    );
  }
}