import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:miniproject/home.dart';
import 'package:miniproject/newlogin.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  String _currentAnimation = "asset/cat.json.json";

  void _changeAnimation(String animationAsset) {
    setState(() {
      _currentAnimation = animationAsset;
    });
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    Future.delayed(const Duration(seconds: 5), () {
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
      backgroundColor: const Color.fromARGB(255, 3, 44, 91),
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
                "Empetz",
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
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
