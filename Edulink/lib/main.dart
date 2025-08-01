import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:shoppingcart/firebase_options.dart';
import 'package:shoppingcart/login.dart';
import 'package:shoppingcart/splash.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform);
 runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home:Splash() ,
  ));
}

