import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';


import 'package:shoppingcart/login.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  String _currentAnimation = "asset/school.json";

  void _changeAnimation(String animationAsset) {
    setState(() {
      _currentAnimation = animationAsset;
    });
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    Future.delayed(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ));
    });
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:  Colors.white,
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Lottie Animation
            Lottie.asset(
              _currentAnimation,
              height: 300,
              fit: BoxFit.contain,
            ),

            // Text on top of Lottie animation
            Positioned(
              top: 5,
              child: Text(
                "EduLink",
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 6, 48, 83),
                  fontFamily: 'Cursive',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
